// This Jenkinsfile defines internal MarkLogic build pipeline.

/* groovylint-disable CatchException, CompileStatic, DuplicateStringLiteral, LineLength, MethodName, MethodParameterTypeRequired, MethodReturnTypeRequired, NoDef, UnnecessaryGetter, UnusedVariable, VariableName, VariableTypeRequired */

//Shared library definitions: https://github.com/marklogic/MarkLogic-Build-Libs/tree/1.0-declarative/vars
@Library('shared-libraries@1.0-declarative')
import groovy.json.JsonSlurperClassic

gitCredID = '550650ab-ee92-4d31-a3f4-91a11d5388a3'
JIRA_ID = ''
JIRA_ID_PATTERN = /CLD-\d{3,4}/

// Define local funtions
void PreBuildCheck() {
    // Initialize parameters as environment variables as workaround for https://issues.jenkins-ci.org/browse/JENKINS-41929
    evaluate """${def script = ""; params.each { k, v -> script += "env.${k} = '''${v}'''\n" }; return script}"""

    JIRA_ID = ExtractJiraID()
    echo 'Jira ticket number: ' + JIRA_ID

    if ( env.GIT_URL ) {
        githubAPIUrl = GIT_URL.replace('.git', '').replace('github.com', 'api.github.com/repos')
        echo 'githubAPIUrl: ' + githubAPIUrl
    } else {
        echo 'ERROR: GIT_URL is not defined'
        sh 'exit 1'
    }

    if (env.CHANGE_ID) {
        if (PRDraftCheck()) { sh 'exit 1' }
            if (getReviewState().equalsIgnoreCase('CHANGES_REQUESTED')) {
                println(reviewState)
                sh 'exit 1'
            }
    }

    // def obj = new abortPrevBuilds()
    // obj.abortPrevBuilds()
}

@NonCPS
def ExtractJiraID() {
    // Extract Jira ID from one of the environment variables
    def match
    if (env.CHANGE_TITLE) {
        match = env.CHANGE_TITLE =~ JIRA_ID_PATTERN
    } 
    else if (env.BRANCH_NAME) {
        match = env.BRANCH_NAME =~ JIRA_ID_PATTERN
    }
    else if (env.GIT_BRANCH) {
        match = env.GIT_BRANCH =~ JIRA_ID_PATTERN
    }
    else {
        echo 'ERROR: Jira ticket number not detected.'
        return ''
    }
    try {
        return match[0]
    } catch (any) {
        echo 'ERROR: Jira ticket number not detected.'
        return ''
    }
}

def PRDraftCheck() {
    withCredentials([usernameColonPassword(credentialsId: gitCredID, variable: 'Credentials')]) {
        PrObj = sh(returnStdout: true, script:'''
                     curl -u $Credentials  -X GET  ''' + githubAPIUrl + '''/pulls/$CHANGE_ID
                     ''')
    }
    def jsonObj = new JsonSlurperClassic().parseText(PrObj.toString().trim())
    return jsonObj.draft
}

def getReviewState() {
    def reviewResponse
    def commitHash
    withCredentials([usernameColonPassword(credentialsId: gitCredID, variable: 'Credentials')]) {
        reviewResponse = sh(returnStdout: true, script:'''
                            curl -u $Credentials  -X GET  ''' + githubAPIUrl + '''/pulls/$CHANGE_ID/reviews
                             ''')
         commitHash = sh(returnStdout: true, script:'''
                         curl -u $Credentials  -X GET  ''' + githubAPIUrl + '''/pulls/$CHANGE_ID
                         ''')
    }
    def jsonObj = new JsonSlurperClassic().parseText(commitHash.toString().trim())
    def commit_id = jsonObj.head.sha
    println(commit_id)
    def reviewState = getReviewStateOfPR reviewResponse, 2, commit_id
    echo reviewState
    return reviewState
}

def getServerPath(branchName) {
    switch (branchName) {
        case '10.1':
            return 'rh7v-10-tst-bld-1.eng.marklogic.com/b10_1'
            break
        case '11.0':
            return 'rh7v-i64-11-build/HEAD'
            break
        case '9.0':
            return 'rh7v-90-tst-bld-1.marklogic.com/b9_0'
            break
        default:
            return 'INVALID BRANCH'
    }
}

def ResultNotification(message) {
    def author, authorEmail, emailList
    if (env.CHANGE_AUTHOR) {
        author = env.CHANGE_AUTHOR.toString().trim().toLowerCase()
        authorEmail = getEmailFromGITUser author
        emailList = params.emailList + ',' + authorEmail
    } else {
        emailList = params.emailList
    }

    mail charset: 'UTF-8', mimeType: 'text/html', to: "${emailList}", body: "<b>Jenkins pipeline for ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br>${env.BUILD_URL}</b>", subject: "${message}: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
    if (JIRA_ID) {
        def comment = [ body: "Jenkins pipeline build result: ${message}" ]
        jiraAddComment site: 'JIRA', idOrKey: JIRA_ID, input: comment
    }
}

def CopyRPMs() {
    timeStamp = sh(returnStdout: true, script: 'date +%Y%m%d').trim()
    sh """
        cd src/centos
        if [ -z ${env.ML_RPM} ]; then
            unset RETCODE
            scp ${env.buildServer}:${env.buildServerBasePath}/${env.buildServerPlatform}/${buildServerPath}/pkgs.${timeStamp}/MarkLogic-${params.ML_SERVER_BRANCH}-${timeStamp}.x86_64.rpm . || RETCODE=\$?
            if [ ! -z \$RETCODE ]; then
                count_iter=75
                while [ \$count_iter -gt 0 ] ; do
                    unset RETCODE
                    echo "WARN : unable to copy package!! retrying after 5 mins"
                    sleep 300
                    scp ${env.buildServer}:${env.buildServerBasePath}/${env.buildServerPlatform}/${buildServerPath}/pkgs.${timeStamp}/MarkLogic-${params.ML_SERVER_BRANCH}-${timeStamp}.x86_64.rpm . || RETCODE=\$?
                    if [ -z \$RETCODE ] ; then
                        echo "INFO" "Successfully copied package"
                        break
                    fi
                    let count_iter--
                done
                if [ ! -z \$RETCODE ] ; then
                    echo "ERROR : unable to copy package"
                    false
                else
                    echo "INFO" "Successfully copied package"
                fi
            fi
        else
            cp $ML_RPM .
        fi
    if [ -z ${env.ML_CONVERTERS}]; then
            unset RETCODE
            scp ${env.buildServer}:${env.buildServerBasePath}converter/${buildServerPath}/pkgs.${timeStamp}/MarkLogicConverters-${params.ML_SERVER_BRANCH}-${timeStamp}.x86_64.rpm . || RETCODE=\$?
            if [ ! -z \$RETCODE ]; then
                count_iter=75
                while [ \$count_iter -gt 0 ] ; do
                    unset RETCODE
                    echo "WARN : unable to copy package!! retrying after 5 mins"
                    sleep 300
                    scp ${env.buildServer}:${env.buildServerBasePath}converter/${buildServerPath}/pkgs.${timeStamp}/MarkLogicConverters-${params.ML_SERVER_BRANCH}-${timeStamp}.x86_64.rpm . || RETCODE=\$?
                    if [ -z \$RETCODE ] ; then
                        echo "INFO" "Successfully copied package"
                        break
                    fi
                    let count_iter--
                done
                if [ ! -z \$RETCODE ] ; then
                    echo "ERROR : unable to copy package"
                    false
                else
                    echo "INFO" "Successfully copied package"
                fi
            fi
        else
            cp $ML_CONVERTERS .
        fi
    """
    script {
        RPM = sh(returnStdout: true, script: 'cd src/centos;file MarkLogic-*.rpm | cut -d: -f1').trim()
        CONVERTERS = sh(returnStdout: true, script: 'cd src/centos;file MarkLogicConverters-*.rpm | cut -d: -f1').trim()
        mlVersion = sh(returnStdout: true, script: "echo ${RPM}|  awk -F \"MarkLogic-\" '{print \$2;}'  | awk -F \".x86_64.rpm\"  '{print \$1;}' ").trim()
    }
}

def RunStructureTests() {
    sh """
        cd test
        #insert current version
        sed -i -e 's/VERSION_PLACEHOLDER/${mlVersion}-${env.platformString}-${env.dockerVersion}/' ./structure-test.yml
        curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 && chmod +x container-structure-test-linux-amd64 && mv container-structure-test-linux-amd64 container-structure-test
        ./container-structure-test test --config ./structure-test.yml --image marklogic-centos/marklogic-server-centos:${mlVersion}-${env.platformString}-${env.dockerVersion} --output junit | tee container-structure-test.xml
        #fix junit output
        sed -i -e 's/<\\/testsuites>//' -e 's/<testsuite>//' -e 's/<testsuites/<testsuite name="container-structure-test"/' ./container-structure-test.xml
    """
    junit testResults: '**/container-structure-test.xml'
}

def RunServerRegressionTests() {
    //TODO: run this conditionally for develop and master branches only
    echo 'Server regression tests would execute here'
    // The following can be uncommented to show an interactive prompt for manual regresstion tests
    // input "Server regression tests need to be executed manually. "
}

def PublishToInternalRegistry() {
    withCredentials([usernamePassword(credentialsId: '8c2e0b38-9e97-4953-aa60-f2851bb70cc8', passwordVariable: 'docker_password', usernameVariable: 'docker_user')]) {
        sh """
            docker login -u ${docker_user} -p ${docker_password} ${dockerRegistry}
            cd src/centos
            make push-mlregistry version=${mlVersion}-${env.platformString}-${env.dockerVersion}
        """
    }
}

pipeline {
    agent {
        label {
            label 'docker-vitaly'
        }
    }
    options {
        checkoutToSubdirectory '.'
        buildDiscarder logRotator(artifactDaysToKeepStr: '7', artifactNumToKeepStr: '', daysToKeepStr: '30', numToKeepStr: '')
        skipStagesAfterUnstable()
    }
    environment {
        buildServer = 'distro.marklogic.com'
        buildServerBasePath = '/space/nightly/builds/'
        buildServerPlatform = 'linux64-rh7'
        buildServerPath = getServerPath(params.ML_SERVER_BRANCH)
        dockerRegistry = 'https://ml-docker-dev.marklogic.com'
    }

    parameters {
        string(name: 'emailList', defaultValue: 'vkorolev@marklogic.com', description: 'List of email for build notification', trim: true)
        string(name: 'dockerVersion', defaultValue: '1.0.0-ea4', description: 'ML Docker version. This version along with ML rpm package version will be the image tag as {ML_Version}_{dockerVersion}', trim: true)
        string(name: 'platformString', defaultValue: 'centos', description: 'Platform string for Docker image version. Will be made part of the docker image tag', trim: true)
        choice(name: 'ML_SERVER_BRANCH', choices: '10.1\n11.0\n9.0', description: 'MarkLogic Server Branch. used to pick appropriate rpm')
        string(name: 'ML_RPM', defaultValue: '', description: 'RPM to be used for Image creation. \n If left blank nightly ML rpm will be used.\n Please provide Jenkins accessible path e.g. /project/engineering or /project/qa', trim: true)
        string(name: 'ML_CONVERTERS', defaultValue: '', description: 'The Converters RPM to be included in the image creation \n If left blank the nightly ML Converters Package will be used.', trim: true)
        booleanParam(name: 'PUBLISH_IMAGE', defaultValue: false, description: 'Publish image to internal registry')
    }

    stages {
        stage('Pre-Build-Check') {
            steps {
                PreBuildCheck()
            }
        }

        stage('Copy-RPMs') {
            steps {
                CopyRPMs()
            }
        }

        stage('Build-Image') {
            steps {
                sh "cd src/centos; make build version=${mlVersion}-${env.platformString}-${env.dockerVersion} package=${RPM} converters=${CONVERTERS}"
            }
        }

        stage('Image-Test') {
            steps {
                RunStructureTests()
            }
        }

        stage('Run-Server-Regression-Tests') {
            steps {
                RunServerRegressionTests()
            }
        }

        stage('Publish-Image') {
            when {
                    expression { return params.PUBLISH_IMAGE }
            }
            steps {
                PublishToInternalRegistry()
            }
        }
    }

    post {
        always {
            sh '''
                cd src/centos
                rm -rf *.rpm
            '''
        }
        success {
            ResultNotification('BUILD SUCCESS ✅')
        }
        failure {
            ResultNotification('BUILD ERROR ❌')
        }
        unstable {
            ResultNotification('BUILD UNSTABLE ❌')
        }
    }
}
