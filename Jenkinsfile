/* groovylint-disable CompileStatic, LineLength, VariableTypeRequired */
// This Jenkinsfile defines internal MarkLogic build pipeline.

//Shared library definitions: https://github.com/marklogic/MarkLogic-Build-Libs/tree/1.0-declarative/vars
@Library('shared-libraries@1.0-declarative')
import groovy.json.JsonSlurperClassic

// email list for scheduled builds (includes security vulnerability)
emailList = 'vitaly.korolev@progress.com, Barkha.Choithani@progress.com, Fayez.Saliba@progress.com, Sumanth.Ravipati@progress.com, Peng.Zhou@progress.com'
// email list for security vulnerabilities only
emailSecList = 'Rangan.Doreswamy@progress.com, Mahalakshmi.Srinivasan@progress.com'
gitCredID = 'marklogic-builder-github'
dockerRegistry = 'ml-docker-db-dev-tierpoint.bed-artifactory.bedford.progress.com'
JIRA_ID_PATTERN = /(?i)(MLE)-\d{3,6}/
JIRA_ID = ''
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
            echo 'PR changes requested. (' + reviewState + ') Aborting.'
            sh 'exit 1'
        }
    }
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
        echo 'Warning: No Git title or branch available.'
        return ''
    }
    try {
        return match[0][0]
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

void copyRPMs() {
    if (marklogicVersion == "10") {
        RPMsuffix = "-nightly"
        RPMbranch = "b10"
        RPMversion = "10.0"
    }
    else if (marklogicVersion == "11") {
        RPMsuffix = ".nightly-rhel"
        RPMbranch = "b11"
        RPMversion = "11.2"
    }
    else if (marklogicVersion == "12") {
        RPMsuffix = ".nightly-rhel"
        RPMbranch = "b12"
        RPMversion = "12.0"
    }
    else {
        error "Invalid value in marklogicVersion parameter."
    }
    sh """
        cd src
        if [ -z ${env.ML_RPM} ]; then
            wget --no-verbose https://bed-artifactory.bedford.progress.com:443/artifactory/ml-rpm-tierpoint/${RPMbranch}/server/MarkLogic-${RPMversion}${RPMsuffix}.x86_64.rpm
        else
            wget --no-verbose ${ML_RPM}
        fi
        if [ -z ${env.ML_CONVERTERS}]; then
            wget --no-verbose https://bed-artifactory.bedford.progress.com:443/artifactory/ml-rpm-tierpoint/${RPMbranch}/converters/MarkLogicConverters-${RPMversion}${RPMsuffix}.x86_64.rpm
        else
            wget --no-verbose ${ML_CONVERTERS}
        fi
    """
    script {
        RPM = sh(returnStdout: true, script: 'cd src;file MarkLogic-*.rpm | cut -d: -f1').trim()
        CONVERTERS = sh(returnStdout: true, script: 'cd src;file MarkLogicConverters-*.rpm | cut -d: -f1').trim()
        mlVersion = sh(returnStdout: true, script: "echo ${RPM}|  awk -F \"MarkLogic-\" '{print \$2;}'  | awk -F \".x86_64.rpm\"  '{print \$1;}' | awk -F \"-rhel\"  '{print \$1;}' ").trim()
    }
}

void buildDockerImage() {
    sh "make build docker_image_type=${dockerImageType} version=${mlVersion}-${env.dockerImageType}-${env.dockerVersion} build_branch=${env.BRANCH_NAME} package=${RPM} converters=${CONVERTERS}"
    currentBuild.displayName = "#${BUILD_NUMBER} ${mlVersion}-${env.dockerImageType}-${env.dockerVersion}"
}

void structureTests() {
    sh """
        #install container-structure-test 1.16.0 binary
        curl -s -LO https://storage.googleapis.com/container-structure-test/v1.16.0/container-structure-test-linux-amd64 && chmod +x container-structure-test-linux-amd64 && mv container-structure-test-linux-amd64 container-structure-test
        make structure-test current_image=marklogic/marklogic-server-${dockerImageType}:${mlVersion}-${env.dockerImageType}-${env.dockerVersion} version=${mlVersion}-${env.dockerImageType}-${env.dockerVersion} build_branch=${env.BRANCH_NAME} docker_image_type=${env.dockerImageType} Jenkins=true
    """
}

void dockerTests() {
    sh "make docker-tests current_image=marklogic/marklogic-server-${dockerImageType}:${mlVersion}-${env.dockerImageType}-${env.dockerVersion} version=${mlVersion}-${env.dockerImageType}-${env.dockerVersion} build_branch=${env.BRANCH_NAME} docker_image_type=${dockerImageType}"
}

void lint() {
    IMAGE_INFO = sh(returnStdout: true, script: 'docker images | grep \"marklogic-server-'+"${dockerImageType}"+'\"')

    sh """
        make lint Jenkins=true
        cat start-scripts-lint.txt dockerfile-lint.txt
    """

    LINT_OUTPUT = sh(returnStdout: true, script: "echo start-scripts-lint.txt: ;echo; cat start-scripts-lint.txt; echo; echo dockerfile-lint.txt: ; cat dockerfile-lint.txt; echo").trim()

    sh """
        rm -f start-scripts-lint.txt dockerfile-lint.txt
    """
}

void vulnerabilityScan() {
    sh """
        make scan current_image=marklogic/marklogic-server-${dockerImageType}:${mlVersion}-${env.dockerImageType}-${env.dockerVersion} Jenkins=true
        grep \'High\\|Critical\' scan-server-image.txt
    """

    SCAN_OUTPUT = sh(returnStdout: true, script: 'grep \'High\\|Critical\' scan-server-image.txt')
    if (SCAN_OUTPUT.size()) {
        mail charset: 'UTF-8', mimeType: 'text/html', to: "${emailSecList}", body: "<br>Jenkins pipeline for ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br>Vulnerabilities: <pre><code>${SCAN_OUTPUT}</code></pre>", subject: "Critical or High Security Vulnerabilities Found: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
    }

    sh '''rm -f scan-server-image.txt'''
}

void publishToInternalRegistry() {
    currentImage="marklogic/marklogic-server-${dockerImageType}:${mlVersion}-${env.dockerImageType}-${env.dockerVersion}"
    mlVerShort=mlVersion.split("\\.")[0]
    latestTag="marklogic/marklogic-server-${dockerImageType}:latest-${mlVerShort}"
    withCredentials([usernamePassword(credentialsId: 'builder-credentials-artifactory', passwordVariable: 'docker_password', usernameVariable: 'docker_user')]) {
        sh """
            echo "${docker_password}" | docker login --username ${docker_user} --password-stdin ${dockerRegistry}
            docker tag ${currentImage} ${dockerRegistry}/${currentImage}
            docker tag ${currentImage} ${dockerRegistry}/${latestTag}
            docker push ${dockerRegistry}/${currentImage}
            docker push ${dockerRegistry}/${latestTag}
        """
        
    }
    // Publish to private ECR repository that is used by the performance team. (only ML11)
    if ( params.marklogicVersion == "11" ) {
        withCredentials( [[
            $class: 'AmazonWebServicesCredentialsBinding',
            credentialsId: "aws-engineering-ct-ecr",
            accessKeyVariable: 'AWS_ACCESS_KEY_ID',
            secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
            ]]) {
                sh """
                    aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 713759029616.dkr.ecr.us-west-2.amazonaws.com
                    docker tag ${currentImage} 713759029616.dkr.ecr.us-west-2.amazonaws.com/ml-docker-nightly:${mlVersion}-${env.dockerImageType}-${env.dockerVersion}
	                docker push 713759029616.dkr.ecr.us-west-2.amazonaws.com/ml-docker-nightly:${mlVersion}-${env.dockerImageType}-${env.dockerVersion}
                """
            }
    }

    currentBuild.description = "Published"
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
        parameterizedCron( env.BRANCH_NAME == 'develop' ? '''00 03 * * * % marklogicVersion=10 dockerImageType=centos
                                                             00 04 * * * % marklogicVersion=11 dockerImageType=centos
                                                             00 05 * * * % marklogicVersion=12 dockerImageType=centos
                                                             00 06 * * * % marklogicVersion=11 dockerImageType=ubi''' : '')
    }
    environment {
        QA_LICENSE_KEY = credentials('QA_LICENSE_KEY')
    }

    parameters {
        string(name: 'emailList', defaultValue: emailList, description: 'List of email for build notification', trim: true)
        string(name: 'dockerVersion', defaultValue: '1.1.2', description: 'ML Docker version. This version along with ML rpm package version will be the image tag as {ML_Version}_{dockerVersion}', trim: true)
        choice(name: 'dockerImageType', choices: 'centos\nubi\nubi-rootless', description: 'Platform type for Docker image. Will be made part of the docker image tag')
        choice(name: 'marklogicVersion', choices: '11\n12\n10', description: 'MarkLogic Server Branch. used to pick appropriate rpm')
        string(name: 'ML_RPM', defaultValue: '', description: 'URL for RPM to be used for Image creation. \n If left blank nightly ML rpm will be used.\n Please provide Jenkins accessible path e.g. /project/engineering or /project/qa', trim: true)
        string(name: 'ML_CONVERTERS', defaultValue: '', description: 'URL for the converters RPM to be included in the image creation \n If left blank the nightly ML Converters Package will be used.', trim: true)
        booleanParam(name: 'PUBLISH_IMAGE', defaultValue: false, description: 'Publish image to internal registry')
        booleanParam(name: 'TEST_STRUCTURE', defaultValue: true, description: 'Run container structure tests')
        booleanParam(name: 'DOCKER_TESTS', defaultValue: true, description: 'Run docker tests')
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
                buildDockerImage()
            }
        }

        stage('Lint') {
            steps {
                lint()
            }
        }

        stage('Scan') {
            steps {
                vulnerabilityScan()
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
                dockerTests()
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
                cd src
                rm -rf *.rpm
                docker rm -f $(docker ps -a -q) || true
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
