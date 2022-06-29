/* groovylint-disable LineLength, MethodName */
// This Jenkinsfile defines internal MarkLogic build pipeline.

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
        echo 'Warning: GIT_URL is not defined'
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

def PRDraftCheck() {
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

    if (JIRA_ID) {
        def comment = [ body: "Jenkins pipeline build result: ${message}" ]
        jiraAddComment site: 'JIRA', idOrKey: JIRA_ID, failOnError: false, input: comment
        mail charset: 'UTF-8', mimeType: 'text/html', to: "${emailList}", body: "<b>Jenkins pipeline for ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br>${env.BUILD_URL}<br>https://project.marklogic.com/jira/browse/${JIRA_ID}</b>", subject: "${message}: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
    } else {
        mail charset: 'UTF-8', mimeType: 'text/html', to: "${emailList}", body: "<b>Jenkins pipeline for ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br>${env.BUILD_URL}</b>", subject: "${message}: ${env.JOB_NAME} #${env.BUILD_NUMBER}"

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

def StructureTests() {
    sh """
        cd test
        #insert current version
        sed -i -e 's/VERSION_PLACEHOLDER/${mlVersion}-${env.platformString}-${env.dockerVersion}/' ./structure-test.yaml
        cd ..
        curl -s -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 && chmod +x container-structure-test-linux-amd64 && mv container-structure-test-linux-amd64 container-structure-test
        make structure-test version=${mlVersion}-${env.platformString}-${env.dockerVersion} Jenkins=true
        #fix junit output
        sed -i -e 's/<\\/testsuites>//' -e 's/<testsuite>//' -e 's/<testsuites/<testsuite name="container-structure-test"/' ./container-structure-test.xml
    """
    junit testResults: '**/container-structure-test.xml'
}

def ServerRegressionTests() {
    //TODO: run this conditionally for develop and master branches only
    echo 'Server regression tests would execute here'
    // The following can be uncommented to show an interactive prompt for manual regresstion tests
    // input "Server regression tests need to be executed manually. "
}

def DockerRunTests() {
    echo "----------------- Docker Tests -----------------"
    // Define test parameters
    def testImage="marklogic-centos/marklogic-server-centos:${mlVersion}-${env.platformString}-${env.dockerVersion}"
    def defaultParams='-it -d -p 8000:8000 -p 8001:8001 -p 8002:8002 -p7997:7997'
    def curlCommand='curl -sL'
    def curlCommandAuth='curl -sL --anyauth -u test_admin:test_admin_pass'
    def jUnitReport = "docker-test-results.xml"
    def testCases = readJSON file: './test/docker-test-cases.json'

    //validate JSON data
    assert testCases instanceof Map

    //create credential files for compose
    writeFile(file: "./docker-compose/mldb_admin_username.txt", text: "test_admin")
    writeFile(file: "./docker-compose/mldb_admin_password.txt", text: "test_admin_pass")
    
    def testResults = ''
    def totalTests = 0
    def totalErrors = 0
    def cmdOutput
    def composeFile
    def testCont

    // Run test cases
    testCases.each { key, value ->

        echo "Running "+key+": "+value.description
        // if .yaml config is provided in params, start compose. otherwise docker run is used
        if ( value.params.toString().contains(".yaml")) {
            //update image label in yaml file
            composeFile = readFile(value.params)
            composeFile = composeFile.replaceAll(/image: .*/, "image: "+testImage)
            writeFile( file: value.params, text: composeFile)
            // start docker compose
            sh( returnStdout: true, script: "docker compose -f ${value.params} up -d" )
        } else {
            //insert valid license data in parameters
            value.params = value.params.toString().replaceAll("LICENSE_PLACEHOLDER", "LICENSEE='MarkLogic - Version 9 QA Test License' -e LICENSE_KEY=\"${env.QA_LICENSE_KEY}\"")
            // start docker container
            testCont = sh( returnStdout: true, script: "docker run ${defaultParams} ${value.params} ${testImage}" )
        }

        // TODO find a good way to skip the test on error from invalid params
        // TODO: Find a way to check for server status instead of a wait. (log: Database Modules is online)
        sleep(80)

        echo "-Unauthenticated requests"
        value.expected.unauthenticated.each { test, verify ->
            //TODO if key is 'log' then check for log message
            try {
                cmdOutput = sh( returnStdout: true, script: "${curlCommand} http://localhost:${test}" )
            } catch (e) {
                cmdOutput = 'Curl retured error: '+e.message
            }
            testResults = testResults + '<testcase name="'+value.description+' on '+key+' without credentials on port '+test+'"'
            totalTests += 1
            echo "--Port ${test}: "
            if ( cmdOutput.contains(verify) ) {
                echo "PASS"
                testResults = testResults + '/>'
            } else {
                echo "FAIL"
                testResults = testResults + '><failure type="Text mismatch">'+cmdOutput+'</failure></testcase>'
                totalErrors += 1
            }
            sleep(1)
        }
        echo "-Authenticated requests"
        value.expected.authenticated.each { test, verify ->
            try {
            cmdOutput = sh( returnStdout: true, script: "${curlCommandAuth} http://localhost:${test}" )
            } catch (e) {
                cmdOutput = 'Curl retured error: '+e.message
            }
            testResults = testResults + '<testcase name="'+value.description+' on '+key+' with credentials on port '+test+'"'
            totalTests += 1
            echo "--Port ${test}: "
            if ( cmdOutput.contains(verify) ) {
                echo "PASS"
                testResults = testResults + '/>'
            } else {
                echo "FAIL"
                testResults = testResults + '><failure type="Text mismatch">'+cmdOutput+'</failure></testcase>'
                totalErrors += 1
            }
            sleep(1)
        }
        echo "-Deleting resources"
        if ( value.params.toString().contains(".yaml")) {
            sh( returnStdout: true, script: "docker compose -f ${value.params} down" )
        } else {
            sh( returnStdout: true, script: "docker rm -f ${testCont}" )
        }
        sh( returnStdout: true, script: "docker volume prune -f")
    }
    // Generate JUnit XML file for Jenkins report
    // TODO: find a better way to generate junit file
    def jUnitXML = '<testsuite name="Docker Run Tests" tests="'+totalTests+'" failures="'+totalErrors+'">'
    jUnitXML = jUnitXML + testResults + "</testsuite>"
    writeFile( file: jUnitReport, text: jUnitXML )
    junit testResults: jUnitReport
    echo "-------------- End of Docker Tests --------------"
}

void Lint() {
    sh '''
        make lint Jenkins=true
        cat start-marklogic-lint.txt marklogic-server-centos-lint.txt marklogic-deps-centos-base-lint.txt marklogic-server-centos-base-lint.txt
        rm -f start-marklogic-lint.txt marklogic-server-centos-lint.txt marklogic-deps-centos-base-lint.txt marklogic-server-centos-base-lint.txt
    '''
}

void Scan() {
    sh """
        make scan version=${mlVersion}-${env.platformString}-${env.dockerVersion} Jenkins=true
        grep \'High\\|Critical\' scan-deps-image.txt
        grep \'High\\|Critical\' scan-server-image.txt
    """

    highCriticalVunerabilities = sh(returnStdout: true, script: 'grep \'High\\|Critical\' scan-deps-image.txt; grep \'High\\|Critical\' scan-server-image.txt')
    if (highCriticalVunerabilities.size()) {
        mail mimeType: 'text/plain', to: "${params.emailList}", body: "\nJenkins pipeline for ${env.JOB_NAME} \nBuild Number: ${env.BUILD_NUMBER} \n${env.BUILD_URL}\nhttps://project.marklogic.com/jira/browse/${JIRA_ID}\nVulnerabilities: \n${highCriticalVunerabilities}", subject: "Critical or High Security Vulnerabilities Found: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
    }

    sh '''rm -f scan-deps-image.txt scan-server-image.txt'''
}

def PublishToInternalRegistry() {
    withCredentials([usernamePassword(credentialsId: '8c2e0b38-9e97-4953-aa60-f2851bb70cc8', passwordVariable: 'docker_password', usernameVariable: 'docker_user')]) {
        sh """
            docker login -u ${docker_user} -p ${docker_password} ${dockerRegistry}
            make push-mlregistry version=${mlVersion}-${env.platformString}-${env.dockerVersion}
        """
    }
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
    triggers { cron(env.BRANCH_NAME == 'develop' ? '01 01 * * *' : '') }
    environment {
        buildServer = 'distro.marklogic.com'
        buildServerBasePath = '/space/nightly/builds/'
        buildServerPlatform = 'linux64-rh7'
        buildServerPath = getServerPath(params.ML_SERVER_BRANCH)
        dockerRegistry = 'https://ml-docker-dev.marklogic.com'
        QA_LICENSE_KEY = credentials('QA_LICENSE_KEY')
    }

    parameters {
        string(name: 'emailList', defaultValue: 'vkorolev@marklogic.com', description: 'List of email for build notification', trim: true)
        string(name: 'dockerVersion', defaultValue: '1.0.0-ea4', description: 'ML Docker version. This version along with ML rpm package version will be the image tag as {ML_Version}_{dockerVersion}', trim: true)
        string(name: 'platformString', defaultValue: 'centos', description: 'Platform string for Docker image version. Will be made part of the docker image tag', trim: true)
        choice(name: 'ML_SERVER_BRANCH', choices: '10.1\n11.0\n9.0', description: 'MarkLogic Server Branch. used to pick appropriate rpm')
        string(name: 'ML_RPM', defaultValue: '', description: 'RPM to be used for Image creation. \n If left blank nightly ML rpm will be used.\n Please provide Jenkins accessible path e.g. /project/engineering or /project/qa', trim: true)
        string(name: 'ML_CONVERTERS', defaultValue: '', description: 'The Converters RPM to be included in the image creation \n If left blank the nightly ML Converters Package will be used.', trim: true)
        booleanParam(name: 'PUBLISH_IMAGE', defaultValue: false, description: 'Publish image to internal registry')
        booleanParam(name: 'TEST_STRUCTURE', defaultValue: true, description: 'Run container structure tests')
        booleanParam(name: 'DOCKER_TESTS', defaultValue: true, description: 'Run server regression tests')
        booleanParam(name: 'SERVER_REGRESSION', defaultValue: true, description: 'Run server regression tests')
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
                sh "make build version=${mlVersion}-${env.platformString}-${env.dockerVersion} package=${RPM} converters=${CONVERTERS}"
            }
        }

        stage('Lint') {
            steps {
                Lint()
            }
        }

        stage('Scan') {
            steps {
                Scan()
            }
        }

        stage('Structure-Tests') {
            when {
                expression { return params.TEST_STRUCTURE }
            }
            steps {
                StructureTests()
            }
        }

        stage('Docker-Run-Tests') {
            when {
                expression { return params.DOCKER_TESTS }
            }
            steps {
                DockerRunTests()
            }
        }

        stage('Run-Server-Regression-Tests') {
            when {
                expression { return params.SERVER_REGRESSION }
            }
            steps {
                ServerRegressionTests()
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
                PublishToInternalRegistry()
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