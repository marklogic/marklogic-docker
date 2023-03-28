/* groovylint-disable CompileStatic, LineLength, VariableTypeRequired */
// This Jenkinsfile defines internal MarkLogic build pipeline.

//Shared library definitions: https://github.com/marklogic/MarkLogic-Build-Libs/tree/1.0-declarative/vars
@Library('shared-libraries@1.0-declarative')
import groovy.json.JsonSlurperClassic

// email list for scheduled builds (includes security vulnerability)
emailList = 'vkorolev@marklogic.com, irosenba@marklogic.com, Barkha.Choithani@marklogic.com, Fayez.Saliba@marklogic.com, Sumanth.Ravipati@marklogic.com, Peng.Zhou@marklogic.com'
// email list for security vulnerabilities only
emailSecList = 'Rangan.Doreswamy@marklogic.com, Mahalakshmi.Srinivasan@marklogic.com'
gitCredID = '550650ab-ee92-4d31-a3f4-91a11d5388a3'
JIRA_ID = ''
JIRA_ID_PATTERN = /CLD-\d{3,4}/
LINT_OUTPUT = ''
SCAN_OUTPUT = ''
IMAGE_INFO = 0
// Define local funtions
void preBuildCheck() {
    // Initialize parameters as env variables as workaround for https://issues.jenkins-ci.org/browse/JENKINS-41929
    evaluate """${ def script = ''; params.each { k, v -> script += "env.${k} = '''${v}'''\n" }; return script}"""

    JIRA_ID = extractJiraID()
    echo 'Jira ticket number: ' + JIRA_ID

    if (env.GIT_URL) {
        githubAPIUrl = GIT_URL.replace('.git', '').replace('github.com', 'api.github.com/repos')
        echo 'githubAPIUrl: ' + githubAPIUrl
    } else {
        echo 'Warning: GIT_URL is not defined'
    }

    if (env.CHANGE_ID) {
        if (prDraftCheck()) { sh 'exit 1' }
        if (getReviewState().equalsIgnoreCase('CHANGES_REQUESTED')) {
            println(reviewState)
            sh 'exit 1'
        }
    }

// def obj = new abortPrevBuilds()
// obj.abortPrevBuilds()
}

@NonCPS
def extractJiraID() {
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
        echo 'Warning: Jira ticket number not detected.'
        return ''
    }
    try {
        return match[0]
    } catch (any) {
        echo 'Warning: Jira ticket number not detected.'
        return ''
    }
}

def prDraftCheck() {
    withCredentials([usernameColonPassword(credentialsId: gitCredID, variable: 'Credentials')]) {
        PrObj = sh(returnStdout: true, script:'''
                    curl -s -u $Credentials  -X GET  ''' + githubAPIUrl + '''/pulls/$CHANGE_ID
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
                            curl -s -u $Credentials  -X GET  ''' + githubAPIUrl + '''/pulls/$CHANGE_ID/reviews
                            ''')
        commitHash = sh(returnStdout: true, script:'''
                        curl -s -u $Credentials  -X GET  ''' + githubAPIUrl + '''/pulls/$CHANGE_ID
                        ''')
    }
    def jsonObj = new JsonSlurperClassic().parseText(commitHash.toString().trim())
    def commitId = jsonObj.head.sha
    println(commit_id)
    def reviewState = getReviewStateOfPR reviewResponse, 2, commitId
    echo reviewState
    return reviewState
}

void resultNotification(message) {
    def author, authorEmail, emailList
    if (env.CHANGE_AUTHOR) {
        author = env.CHANGE_AUTHOR.toString().trim().toLowerCase()
        authorEmail = getEmailFromGITUser author
        emailList = params.emailList + ',' + authorEmail
    } else {
        emailList = params.emailList
    }
    jira_link = "https://project.marklogic.com/jira/browse/${JIRA_ID}"
    email_body = "<b>Jenkins pipeline for</b> ${env.JOB_NAME} <br><b>Build Number: </b>${env.BUILD_NUMBER} <b><br><br>Lint Output: <br></b><pre><code>${LINT_OUTPUT}</code></pre><br><b>Vulnerabilities: </b><pre><code>${SCAN_OUTPUT}</code></pre> <br><b>Image Details: <br></b>${IMAGE_INFO} <br><br><b>Build URL: </b><br>${env.BUILD_URL}"
    jira_email_body = "${email_body} <br><br><b>Jira URL: </b><br>${jira_link}"

    if (JIRA_ID) {
        def comment = [ body: "Jenkins pipeline build result: ${message}" ]
        jiraAddComment site: 'JIRA', idOrKey: JIRA_ID, failOnError: false, input: comment
        mail charset: 'UTF-8', mimeType: 'text/html', to: "${emailList}", body: "${jira_email_body}", subject: "${message}: ${env.JOB_NAME} #${env.BUILD_NUMBER} - ${JIRA_ID}"
    } else {
        mail charset: 'UTF-8', mimeType: 'text/html', to: "${emailList}", body: "${email_body}", subject: "${message}: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
    }
}

String getServerVersion(branchName) {
    switch (branchName) {
        case 'develop':
            return '12.0'
        case 'develop-11':
            return '11.1'
        case 'develop-10.0':
            return '10.0'
        case 'develop-9.0':
            return '9.0'
        default:
            return 'INVALID BRANCH'
    }
}

void copyRPMs() {
    timeStamp = sh(returnStdout: true, script: 'date +%Y%m%d').trim()
    if (buildServerVersion == "11.1" || buildServerVersion == "12.0") {
        RPMsuffix = ".${timeStamp}-rhel"
    }
    else {
        RPMsuffix = "-${timeStamp}"
    }
    sh """
        cd src/centos
        if [ -z ${env.ML_RPM} ]; then
            unset RETCODE
            scp ${env.buildServer}:${env.buildServerBasePath}/${env.buildServerPlatform}/${buildServerPath}/pkgs.${timeStamp}/MarkLogic-${buildServerVersion}${RPMsuffix}.x86_64.rpm . || RETCODE=\$?
            if [ ! -z \$RETCODE ]; then
                count_iter=75
                while [ \$count_iter -gt 0 ] ; do
                    unset RETCODE
                    echo "WARN : unable to copy package!! retrying after 5 mins"
                    sleep 300
                    scp ${env.buildServer}:${env.buildServerBasePath}/${env.buildServerPlatform}/${buildServerPath}/pkgs.${timeStamp}/MarkLogic-${buildServerVersion}${RPMsuffix}.x86_64.rpm . || RETCODE=\$?
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
            scp ${env.buildServer}:${env.buildServerBasePath}/converter/${buildServerPath}/pkgs.${timeStamp}/MarkLogicConverters-${buildServerVersion}${RPMsuffix}.x86_64.rpm . || RETCODE=\$?
            if [ ! -z \$RETCODE ]; then
                count_iter=75
                while [ \$count_iter -gt 0 ] ; do
                    unset RETCODE
                    echo "WARN : unable to copy package!! retrying after 5 mins"
                    sleep 300
                    scp ${env.buildServer}:${env.buildServerBasePath}converter/${buildServerPath}/pkgs.${timeStamp}/MarkLogicConverters-${buildServerVersion}${RPMsuffix}.x86_64.rpm . || RETCODE=\$?
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
        mlVersion = sh(returnStdout: true, script: "echo ${RPM}|  awk -F \"MarkLogic-\" '{print \$2;}'  | awk -F \".x86_64.rpm\"  '{print \$1;}' | awk -F \"-rhel\"  '{print \$1;}' ").trim()
    }
}

void structureTests() {
    sh """
        cd test
        #insert current version
        sed -i -e 's^VERSION_PLACEHOLDER^${mlVersion}-${env.platformString}-${env.dockerVersion}^g' -e 's^BRANCH_PLACEHOLDER^${env.BRANCH_NAME}^g' ./structure-test.yaml
        cd ..
        curl -s -LO https://storage.googleapis.com/container-structure-test/v1.11.0/container-structure-test-linux-amd64 && chmod +x container-structure-test-linux-amd64 && mv container-structure-test-linux-amd64 container-structure-test
        make structure-test version=${mlVersion}-${env.platformString}-${env.dockerVersion} Jenkins=true
        #fix junit output
        sed -i -e 's/<\\/testsuites>//' -e 's/<testsuite>//' -e 's/<testsuites/<testsuite name="container-structure-test"/' ./container-structure-test.xml
    """
}

void serverRegressionTests() {
    //TODO: run this conditionally for develop and master branches only
    echo 'Server regression tests would execute here'
// The following can be uncommented to show an interactive prompt for manual regresstion tests
// input "Server regression tests need to be executed manually. "
}

void lint() {
    IMAGE_INFO = sh(returnStdout: true, script: 'docker  images | grep \"marklogic-server-centos\"')

    sh '''
        make lint Jenkins=true
        cat start-marklogic-lint.txt marklogic-deps-centos-base-lint.txt marklogic-server-centos-base-lint.txt
    '''

    LINT_OUTPUT = sh(returnStdout: true, script: 'echo start-marklogic.sh: ;echo; cat start-marklogic-lint.txt; echo dockerfile-marklogic-server-centos: ; echo marklogic-deps-centos:base: ;echo; cat marklogic-deps-centos-base-lint.txt; echo marklogic-server-centos:base: ;echo; cat marklogic-server-centos-base-lint.txt').trim()

    sh '''
        rm -f start-marklogic-lint.txt marklogic-deps-centos-base-lint.txt marklogic-server-centos-base-lint.txt
    '''
}

void scan() {
    sh """
        make scan version=${mlVersion}-${env.platformString}-${env.dockerVersion} Jenkins=true
        grep \'High\\|Critical\' scan-server-image.txt
    """

    SCAN_OUTPUT = sh(returnStdout: true, script: 'grep \'High\\|Critical\' scan-server-image.txt')
    if (SCAN_OUTPUT.size()) {
        mail charset: 'UTF-8', mimeType: 'text/html', to: "${emailSecList}", body: "<br>Jenkins pipeline for ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br>Vulnerabilities: <pre><code>${SCAN_OUTPUT}</code></pre>", subject: "Critical or High Security Vulnerabilities Found: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
    }

    sh '''rm -f scan-server-image.txt'''
}

void publishToInternalRegistry() {
    publishTag="${mlVersion}-${env.platformString}-${env.dockerVersion}"
    withCredentials([usernamePassword(credentialsId: '8c2e0b38-9e97-4953-aa60-f2851bb70cc8', passwordVariable: 'docker_password', usernameVariable: 'docker_user')]) {
        sh """
            echo "${docker_password}" | docker login --username ${docker_user} --password-stdin ${dockerRegistry}
            make push-mlregistry version=${publishTag}
        """
        
    }
    // Publish to private ECR repository that is used by the performance team. (only ML11)
    if ( params.ML_SERVER_BRANCH == "develop-11" ) {
        withCredentials( [[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: "aws-engineering-ct-ecr",
            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
            ]]) {
                sh """
                    aws ecr get-login --no-include-email --region us-west-2 | bash
                    docker tag marklogic-centos/marklogic-server-centos:${publishTag} 713759029616.dkr.ecr.us-west-2.amazonaws.com/ml-docker-nightly:${publishTag}
	                docker push 713759029616.dkr.ecr.us-west-2.amazonaws.com/ml-docker-nightly:${publishTag}
                """
            }
    }

    currentBuild.description = "Publish ${publishTag}" 
}

void publishTestResults() {
    junit allowEmptyResults:true, testResults: '**/test_results/docker-tests.xml,**/container-structure-test.xml'
    publishHTML allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'test/test_results', reportFiles: 'report.html', reportName: 'Docker Tests Report', reportTitles: ''
}

pipeline {
    agent {
        label {
            label 'cld-docker'
        }
    }
    options {
        checkoutToSubdirectory '.'
        buildDiscarder logRotator(artifactDaysToKeepStr: '7', artifactNumToKeepStr: '', daysToKeepStr: '30', numToKeepStr: '')
        skipStagesAfterUnstable()
    }
    triggers {
        parameterizedCron( env.BRANCH_NAME == 'develop' ? '''00 03 * * * % ML_SERVER_BRANCH=develop-10.0
                                                             00 04 * * * % ML_SERVER_BRANCH=develop-11
                                                             00 05 * * * % ML_SERVER_BRANCH=develop''' : '')
    }
    environment {
        buildServer = 'distro.marklogic.com'
        buildServerBasePath = '/space/nightly/builds'
        buildServerPlatform = 'linux64-rh7'
        buildServerPath = "*/${params.ML_SERVER_BRANCH}"
        buildServerVersion = getServerVersion(params.ML_SERVER_BRANCH)
        dockerRegistry = 'https://ml-docker-dev.marklogic.com'
        QA_LICENSE_KEY = credentials('QA_LICENSE_KEY')
    }

    parameters {
        string(name: 'emailList', defaultValue: emailList, description: 'List of email for build notification', trim: true)
        string(name: 'dockerVersion', defaultValue: '1.0.1', description: 'ML Docker version. This version along with ML rpm package version will be the image tag as {ML_Version}_{dockerVersion}', trim: true)
        string(name: 'platformString', defaultValue: 'centos', description: 'Platform string for Docker image version. Will be made part of the docker image tag', trim: true)
        choice(name: 'ML_SERVER_BRANCH', choices: 'develop-11\ndevelop\ndevelop-10.0\ndevelop-9.0', description: 'MarkLogic Server Branch. used to pick appropriate rpm')
        string(name: 'ML_RPM', defaultValue: '', description: 'RPM to be used for Image creation. \n If left blank nightly ML rpm will be used.\n Please provide Jenkins accessible path e.g. /project/engineering or /project/qa', trim: true)
        string(name: 'ML_CONVERTERS', defaultValue: '', description: 'The Converters RPM to be included in the image creation \n If left blank the nightly ML Converters Package will be used.', trim: true)
        booleanParam(name: 'PUBLISH_IMAGE', defaultValue: false, description: 'Publish image to internal registry')
        booleanParam(name: 'TEST_STRUCTURE', defaultValue: true, description: 'Run container structure tests')
        booleanParam(name: 'DOCKER_TESTS', defaultValue: true, description: 'Run docker tests')
        booleanParam(name: 'SERVER_REGRESSION', defaultValue: true, description: 'Run server regression tests')
    }

    stages {
        stage('Pre-Build-Check') {
            steps {
                preBuildCheck()
            }
        }

        stage('Copy-RPMs') {
            steps {
                copyRPMs()
            }
        }

        stage('Build-Image') {
            steps {
                sh "make build version=${mlVersion}-${env.platformString}-${env.dockerVersion} build_branch=${env.BRANCH_NAME} package=${RPM} converters=${CONVERTERS}"
            }
        }

        stage('Lint') {
            steps {
                lint()
            }
        }

        stage('Scan') {
            steps {
                scan()
            }
        }

        stage('Structure-Tests') {
            when {
                expression { return params.TEST_STRUCTURE }
            }
            steps {
                structureTests()
            }
        }

        stage('Docker-Run-Tests') {
            when {
                expression { return params.DOCKER_TESTS }
            }
            steps {
                sh "make docker-tests test_image=marklogic-centos/marklogic-server-centos:${mlVersion}-${env.platformString}-${env.dockerVersion} version=${mlVersion}-${env.platformString}-${env.dockerVersion} build_branch=${env.BRANCH_NAME}"
            }
        }

        stage('Run-Server-Regression-Tests') {
            when {
                expression { return params.SERVER_REGRESSION }
            }
            steps {
                serverRegressionTests()
            }
        }

        stage('Publish-Image') {
            when {
                    anyOf {
                        branch 'develop'
                        expression { return params.PUBLISH_IMAGE }
                    }
            }
            steps {
                publishToInternalRegistry()
            }
        }
    }

    post {
        always {
            sh '''
                cd src/centos
                rm -rf *.rpm
                docker system prune --force --filter "until=720h"
                docker volume prune --force
                docker image prune --force --all
            '''
            publishTestResults()
        }
        success {
            resultNotification('BUILD SUCCESS ✅')
        }
        failure {
            resultNotification('BUILD ERROR ❌')
        }
        unstable {
            resultNotification('BUILD UNSTABLE ❌')
        }
    }
}
