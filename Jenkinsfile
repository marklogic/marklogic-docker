// Copyright © 2018-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
// This Jenkinsfile defines internal MarkLogic build pipeline.
// The pipeline builds, tests, scans, and optionally publishes MarkLogic Docker images.
// It can be triggered manually, by pull requests, or on a schedule.

//Shared library definitions: https://github.com/marklogic/MarkLogic-Build-Libs/tree/1.0-declarative/vars
@Library('shared-libraries@1.0-declarative')
import groovy.json.JsonSlurperClassic

// email list for scheduled builds (includes security vulnerability)
emailList = 'vitaly.korolev@progress.com, Barkha.Choithani@progress.com, Sumanth.Ravipati@progress.com, Peng.Zhou@progress.com, romain.winieski@progress.com'
// email list for security vulnerabilities only
emailSecList = 'Mahalakshmi.Srinivasan@progress.com'
gitCredID = 'marklogic-builder-github'
dockerRegistry = 'ml-docker-db-dev-tierpoint.bed-artifactory.bedford.progress.com'
pdcRegistry = 'sandboxpdc.azurecr.io'
JIRA_ID_PATTERN = /(?i)(MLE)-\d{3,6}/
JIRA_ID = ''
LINT_OUTPUT = ''
SCAN_OUTPUT = ''
IMAGE_SIZE = 0
RPMversion = ''

// Define local funtions

/**
 * Performs pre-build checks:
 * - Initializes parameters as environment variables.
 * - Extracts Jira ID from branch name or PR title.
 * - Checks if the PR is a draft or has requested changes (for PR builds).
 */
void preBuildCheck() {
    // Initialize parameters as env variables (workaround for https://issues.jenkins-ci.org/browse/JENKINS-41929)
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

/**
 * Extracts a Jira ID (e.g., MLE-1234) from the PR title or branch name.
 * @return The extracted Jira ID string, or an empty string if not found.
 */
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

/**
 * Checks if the current Pull Request is marked as a draft via GitHub API.
 * Requires CHANGE_ID and GIT_URL environment variables.
 * @return true if the PR is a draft, false otherwise.
 */
def prDraftCheck() {
    withCredentials([usernameColonPassword(credentialsId: gitCredID, variable: 'Credentials')]) {
        PrObj = sh(returnStdout: true, script:'''
                    curl -s -u $Credentials  -X GET  ''' + githubAPIUrl + '''/pulls/$CHANGE_ID
                    ''')
    }
    def jsonObj = new JsonSlurperClassic().parseText(PrObj.toString().trim())
    return jsonObj.draft
}

/**
 * Gets the review state of the current Pull Request via GitHub API.
 * Requires CHANGE_ID and GIT_URL environment variables.
 * @return The review state string (e.g., 'APPROVED', 'CHANGES_REQUESTED').
 */
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

/**
 * Sends an email notification with the build status and summary.
 * Includes links to build URL, test reports, scan reports, and Jira ticket (if found).
 * @param status The build status string (e.g., 'Success', 'Failure').
 */
void resultNotification(status) {
    def author, authorEmail, emailList
    if (env.CHANGE_AUTHOR) {
        author = env.CHANGE_AUTHOR.toString().trim().toLowerCase()
        authorEmail = getEmailFromGITUser author
        emailList = params.emailList + ',' + authorEmail
    } else {
        emailList = params.emailList
    }
    
    email_body = "<b>Build URL: </b><a href='${env.BUILD_URL}'>${env.BUILD_URL}</a><br/>" +
                 "<b>Image type: </b>${env.dockerImageType}<br/><br/>" +
                 "<b>Lint Output: </b><br/>" +
                 "<pre><code>${LINT_OUTPUT}</code></pre><br/>" +
                 "<b>Vulnerabilities: </b><pre><code>${SCAN_OUTPUT}</code></pre><br/>" +
                 "<b><a href='${env.BUILD_URL}artifact/scan/report-${env.dockerImageType}.json'>Full scan report.</a></b><br/>" +
                 "<b>Image Size:  <br/></b>${IMAGE_SIZE} <br/>" +
                 "<pre><code>docker pull ${dockerRegistry}/${latestTag}</code></pre><br/><br/>"
    if (params.DOCKER_TESTS) {
        email_body = "${email_body} <b><a href='${env.BUILD_URL}Docker_20Tests_20Report'>Docker Tests Report</a></b><br/>"
    } else {
        email_body = "${email_body} <b>Docker Tests Skipped</b><br/>"
    }
    if (params.SCAP_SCAN) {
        email_body = "${email_body} <b><a href='${env.BUILD_URL}Open_20SCAP_20Report'>SCAP Scan Report</a></b><br/>"
        if ( BRANCH_NAME == 'develop' ) {
            emailList = emailList+','+emailSecList
        }
    } else {
        email_body = "${email_body} <b>SCAP Scan Skipped</b><br/>"
    }
 
    // If Jira ID is available, add comment to the ticket and add link to email.
    if (JIRA_ID) {
        def jira_link = "https://progresssoftware.atlassian.net/browse/${JIRA_ID}"
        def comment = [ body: "Jenkins pipeline build result: ${status}" ]
        jiraAddComment site: 'JIRA',
            input: comment,
            idOrKey: JIRA_ID,
            failOnError: false
        email_body = "${email_body} <br/><br/><b>Jira URL: </b><br/><a href='${jira_link}'>${jira_link}</a>"
    }
    mail to: "${emailList}",
        body: "${email_body}",
        subject: "🥷 ${status}: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
        charset: 'UTF-8', mimeType: 'text/html'
}

/**
 * Copies the MarkLogic Server and Converters RPMs.
 * Determines the correct RPM version/branch based on marklogicVersion parameter.
 * Downloads nightly builds from Artifactory unless specific RPM URLs are provided via ML_RPM/ML_CONVERTERS parameters.
 * Sets RPM, CONVERTERS, and marklogicVersion global variables.
 */
void copyRPMs() {
    if (marklogicVersion == "10") {
        RPMsuffix = "-nightly"
        RPMbranch = "b10"
        RPMversion = "10.0"
    }
    else if (marklogicVersion == "11") {
        //if dockerImageType contains "ubi9" then use nightly-rhel9 suffix
        if (dockerImageType.contains("ubi9")) {
            RPMsuffix = ".nightly-rhel9"
        } else {
            RPMsuffix = ".nightly-rhel"
        }
        RPMbranch = "b11"
        RPMversion = "11.3"
    }
    else if (marklogicVersion == "12") {
        //if dockerImageType contains "ubi9" then use nightly-rhel9 suffix
        if (dockerImageType.contains("ubi9")) {
            RPMsuffix = ".nightly-rhel9"
        } else {
            RPMsuffix = ".nightly-rhel"
        }
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
        // Get the RPM and Converters file names
        RPM = sh(returnStdout: true, script: 'cd src;file MarkLogic-*.rpm | cut -d: -f1').trim()
        CONVERTERS = sh(returnStdout: true, script: 'cd src;file MarkLogicConverters-*.rpm | cut -d: -f1').trim()
        // Extract MarkLogic version from RPM file name
        marklogicVersion = sh(returnStdout: true, script: "echo ${RPM}|  awk -F \"MarkLogic-\" '{print \$2;}'  | awk -F \".x86_64.rpm\"  '{print \$1;}' | awk -F \"-rhel\"  '{print \$1;}' ").trim()
    }
}

/**
 * Builds the Docker image using the 'make build' target.
 * Sets various image tag variables (builtImage, publishImage, latestTag).
 * Updates the Jenkins build display name.
 */
void buildDockerImage() {
    builtImage="marklogic/marklogic-server-${dockerImageType}:${marklogicVersion}-${env.dockerImageType}-${env.dockerVersion}"
    publishImage="marklogic/marklogic-server-${dockerImageType}:${marklogicVersion}-${env.dockerImageType}"
    mlVerShort=marklogicVersion.split("\\.")[0]
    latestTag="marklogic/marklogic-server-${dockerImageType}:latest-${mlVerShort}"
    sh "make build docker_image_type=${dockerImageType} dockerTag=${marklogicVersion}-${env.dockerImageType}-${env.dockerVersion} marklogicVersion=${marklogicVersion} dockerVersion=${env.dockerVersion} build_branch=${env.BRANCH_NAME} package=${RPM} converters=${CONVERTERS}"
    currentBuild.displayName = "#${BUILD_NUMBER}: ${marklogicVersion}-${env.dockerImageType} (${env.dockerVersion})"
}

/**
 * Pulls the Docker image required for upgrade testing.
 * Uses the 'upgradeDockerImage' parameter or defaults to a corresponding 'ubi' image.
 * Skips the pull if the target image is 'ubi-rootless' and DOCKER_TESTS is false.
 */
void pullUpgradeDockerImage() {
    if (dockerImageType == "ubi-rootless" && params.DOCKER_TESTS != "true") {
        sh """
            echo 'dockerImageType is set to ubi-rootless, skipping this stage and Docker upgrade test.'
        """
    } else {
        if (upgradeDockerImage != "" ) {
            sh """
                echo 'upgradeDockerImage: ${upgradeDockerImage}'
                docker pull ${upgradeDockerImage}
            """
        } else {
            upgradeDockerImage = "${dockerRegistry}/marklogic/marklogic-server-ubi:${marklogicVersion}-ubi-${env.dockerVersion}"
            sh """
                echo 'upgradeDockerImage is not specified, using ${upgradeDockerImage} for upgrade test.'
                docker pull ${dockerRegistry}/marklogic/marklogic-server-ubi:${marklogicVersion}-ubi-${env.dockerVersion}
            """
        }
    }
}

/**
 * Runs container structure tests using the 'make structure-test' target.
 */
void structureTests() {
    sh """
        #install container-structure-test 1.16.0 binary
        curl -s -LO https://storage.googleapis.com/container-structure-test/v1.16.0/container-structure-test-linux-amd64 && chmod +x container-structure-test-linux-amd64 && mv container-structure-test-linux-amd64 container-structure-test
        make structure-test current_image=marklogic/marklogic-server-${dockerImageType}:${marklogicVersion}-${env.dockerImageType}-${env.dockerVersion} marklogicVersion=${marklogicVersion} dockerVersion=${env.dockerVersion} build_branch=${env.BRANCH_NAME} docker_image_type=${env.dockerImageType} Jenkins=true
    """
}

/**
 * Runs Docker functional tests using the 'make docker-tests' target.
 */
void dockerTests() {
    sh "make docker-tests current_image=marklogic/marklogic-server-${dockerImageType}:${marklogicVersion}-${env.dockerImageType}-${env.dockerVersion} upgrade_image=${upgradeDockerImage} marklogicVersion=${marklogicVersion} build_branch=${env.BRANCH_NAME} dockerVersion=${env.dockerVersion} docker_image_type=${dockerImageType}"
}

/**
 * Lints the Dockerfile and startup scripts using hadolint and shellcheck via 'make lint'.
 * Captures the lint output in the LINT_OUTPUT variable.
 * Records the built image size in the IMAGE_SIZE variable.
 */
void lint() {
    IMAGE_SIZE = sh(returnStdout: true, script: "docker images marklogic/marklogic-server-${dockerImageType}:${marklogicVersion}-${env.dockerImageType}-${env.dockerVersion} --format '{{.Repository}}:{{.Tag}}\t{{.Size}}'")

    sh """
        make lint Jenkins=true
        cat start-scripts-lint.txt dockerfile-lint.txt
    """

    LINT_OUTPUT = sh(returnStdout: true, script: "echo start-scripts-lint.txt: ;echo; cat start-scripts-lint.txt; echo; echo dockerfile-lint.txt: ; cat dockerfile-lint.txt; echo").trim()

    sh """
        rm -f start-scripts-lint.txt dockerfile-lint.txt
    """
}

/**
 * Scans the built Docker image for vulnerabilities using Grype via 'make scan'.
 * Captures the scan summary in the SCAN_OUTPUT variable.
 * Archives the full JSON scan report.
 * Sends an email notification if critical or high severity vulnerabilities are found.
 */
void vulnerabilityScan() {
    sh """
        make scan current_image=marklogic/marklogic-server-${dockerImageType}:${marklogicVersion}-${env.dockerImageType}-${env.dockerVersion} docker_image_type=${dockerImageType} Jenkins=true
    """
    SCAN_OUTPUT = sh(returnStdout: true, script: "cat scan/report-${env.dockerImageType}.txt")
    sh 'echo "SCAN_OUTPUT: ${SCAN_OUTPUT}"'
    if (SCAN_OUTPUT.size()) {
        mail charset: 'UTF-8', mimeType: 'text/html', to: "${emailSecList}", body: "<br/>Jenkins pipeline for ${env.JOB_NAME} <br/>Build Number: ${env.BUILD_NUMBER} <br/>Vulnerabilities: <pre><code>${SCAN_OUTPUT}</code></pre>", subject: "Critical or High Security Vulnerabilities Found: ${env.JOB_NAME} #${env.BUILD_NUMBER}"
    }
    archiveArtifacts artifacts: 'scan/*', onlyIfSuccessful: true
}

/**
 * Publishes the built Docker image to the internal Artifactory registry.
 * Also publishes ML11 images to a private AWS ECR repository.
 * Tags the image with multiple tags (version-specific, branch-specific, latest).
 * Requires Artifactory and AWS credentials.
 */
void publishToInternalRegistry() {
    withCredentials([usernamePassword(credentialsId: 'builder-credentials-artifactory', passwordVariable: 'docker_password', usernameVariable: 'docker_user')]) {
        sh """
            docker logout ${dockerRegistry}
            echo "${docker_password}" | docker login --username ${docker_user} --password-stdin ${dockerRegistry}
            docker tag ${builtImage} ${dockerRegistry}/${builtImage}
            docker tag ${builtImage} ${dockerRegistry}/${publishImage}
            docker tag ${builtImage} ${dockerRegistry}/${latestTag}
            docker push ${dockerRegistry}/${builtImage}
            docker push ${dockerRegistry}/${publishImage}
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
                    docker tag ${builtImage} 713759029616.dkr.ecr.us-west-2.amazonaws.com/ml-docker-nightly:${marklogicVersion}-${env.dockerImageType}-${env.dockerVersion}
                    docker tag ${builtImage} 713759029616.dkr.ecr.us-west-2.amazonaws.com/ml-docker-nightly:${marklogicVersion}-${env.dockerImageType}
	                docker push 713759029616.dkr.ecr.us-west-2.amazonaws.com/ml-docker-nightly:${marklogicVersion}-${env.dockerImageType}-${env.dockerVersion}
                    docker push 713759029616.dkr.ecr.us-west-2.amazonaws.com/ml-docker-nightly:${marklogicVersion}-${env.dockerImageType}
                """
            }
    }

    // Publish to private ACR Sandbox repository that is used by PDC. (only ML12)
    if ( params.marklogicVersion == "12" ) {
        withCredentials([usernamePassword(credentialsId: 'PDC_SANDBOX_USER', passwordVariable: 'docker_password', usernameVariable: 'docker_user')]) {
            sh """
                echo "${docker_password}" | docker login --username ${docker_user} --password-stdin ${pdcRegistry}
                docker tag ${builtImage} ${pdcRegistry}/ml-docker-nightly:${marklogicVersion}-${env.dockerImageType}-${env.dockerVersion}
                docker tag ${builtImage} ${pdcRegistry}/ml-docker-nightly:${marklogicVersion}-${env.dockerImageType}
                docker push ${pdcRegistry}/ml-docker-nightly:${marklogicVersion}-${env.dockerImageType}-${env.dockerVersion}
                docker push ${pdcRegistry}/ml-docker-nightly:${marklogicVersion}-${env.dockerImageType}
            """
            }
    }

    currentBuild.description = "Published"
}
/**
 * Triggers a BlackDuck scan job for the published image.
 * Runs asynchronously (wait: false).
 */
void scanWithBlackDuck() {
    build job: 'securityscans/Blackduck/KubeNinjas/docker', wait: false, parameters: [ string(name: 'branch', value: "${env.BRANCH_NAME}"), string(name: 'CONTAINER_IMAGES', value: "${dockerRegistry}/${publishImage}") ]
}

/**
 * Publishes JUnit XML test results from structure and Docker tests.
 * Publishes HTML reports for Docker tests and SCAP scans if they were executed.
 */
void publishTestResults() {
    junit allowEmptyResults:true, testResults: '**/test_results/docker-tests.xml,**/container-structure-test.xml'
        if (params.DOCKER_TESTS) {
        echo 'Publishing Docker results..'
        publishHTML allowMissing: false, 
            alwaysLinkToLastBuild: true, 
            keepAll: true, 
            reportDir: 'test/test_results', 
            reportFiles: 'report.html', 
            reportName: 'Docker Tests Report', 
            reportTitles: "Build ${env.BUILD_NUMBER}"
    }
    if (params.SCAP_SCAN) {
        echo 'Publishing SCAP scan results..'
        publishHTML allowMissing: false, 
            alwaysLinkToLastBuild: true, 
            keepAll: true, reportDir: 'scap', 
            reportFiles: 'scap_scan_report.html', 
            reportName: 'Open SCAP Report', 
            reportTitles: "Build ${env.BUILD_NUMBER}"
    }
}

/**
 * Runs an OpenSCAP compliance scan on the rootless image using 'make scap-scan'.
 * Generates an HTML report.
 */
void scapScan() {
    sh """
        make scap-scan current_image=marklogic/marklogic-server-${dockerImageType}:${marklogicVersion}-${env.dockerImageType}-${env.dockerVersion}
    """
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
        // Trigger nightly builds on the develop branch for every supported version of MarkLogic
        // and for every supported image type.
        // Include SCAP scan for rootless images
        parameterizedCron( env.BRANCH_NAME == 'develop' ? '''00 02 * * * % marklogicVersion=10;dockerImageType=ubi
                                                             00 02 * * * % marklogicVersion=10;dockerImageType=ubi-rootless;SCAP_SCAN=true
                                                             00 02 * * * % marklogicVersion=11;dockerImageType=ubi
                                                             30 02 * * * % marklogicVersion=11;dockerImageType=ubi-rootless;SCAP_SCAN=true
                                                             30 02 * * * % marklogicVersion=12;dockerImageType=ubi
                                                             30 02 * * * % marklogicVersion=12;dockerImageType=ubi-rootless;SCAP_SCAN=true
                                                             00 03 * * * % marklogicVersion=11;dockerImageType=ubi9
                                                             00 03 * * * % marklogicVersion=11;dockerImageType=ubi9-rootless;SCAP_SCAN=true''' : '')
    }
    environment {
        QA_LICENSE_KEY = credentials('QA_LICENSE_KEY')
    }

    parameters {
        string(name: 'emailList', defaultValue: emailList, description: 'List of email for build notification', trim: true)
        string(name: 'dockerVersion', defaultValue: '2.1.3', description: 'ML Docker version. This version along with ML rpm package version will be the image tag as {ML_Version}_{dockerVersion}', trim: true)
        choice(name: 'dockerImageType', choices: 'ubi-rootless\nubi\nubi9-rootless\nubi9', description: 'Platform type for Docker image. Will be made part of the docker image tag')
        string(name: 'upgradeDockerImage', defaultValue: '', description: 'Docker image for testing upgrades. Defaults to ubi image if left blank.\n Currently upgrading to ubi-rotless is not supported hence the test is skipped when ubi-rootless image is provided.', trim: true)
        choice(name: 'marklogicVersion', choices: '11\n12\n10', description: 'MarkLogic Server Branch. used to pick appropriate rpm')
        string(name: 'ML_RPM', defaultValue: '', description: 'URL for RPM to be used for Image creation. \n If left blank nightly ML rpm will be used.\n Please provide Jenkins accessible path e.g. /project/engineering or /project/qa', trim: true)
        string(name: 'ML_CONVERTERS', defaultValue: '', description: 'URL for the converters RPM to be included in the image creation \n If left blank the nightly ML Converters Package will be used.', trim: true)
        booleanParam(name: 'PUBLISH_IMAGE', defaultValue: false, description: 'Publish image to internal registry')
        booleanParam(name: 'TEST_STRUCTURE', defaultValue: true, description: 'Run container structure tests')
        booleanParam(name: 'DOCKER_TESTS', defaultValue: true, description: 'Run docker tests')
        booleanParam(name: 'SCAP_SCAN', defaultValue: false, description: 'Run Open SCAP scan on the image.')
    }

    stages {
        // Stage: Perform initial checks (PR status, Jira ID)
        stage('Pre-Build-Check') {
            steps {
                preBuildCheck()
            }
        }

        // Stage: Download MarkLogic Server and Converters RPMs
        stage('Copy-RPMs') {
            steps {
                copyRPMs()
            }
        }

        // Stage: Build the Docker image
        stage('Build-Image') {
            steps {
                buildDockerImage()
            }
        }

        // Stage: Pull the base image needed for upgrade testing
        stage('Pull-Upgrade-Image') {
            steps {
                pullUpgradeDockerImage()
            }
        }

        // Stage: Lint Dockerfile and startup scripts
        stage('Lint') {
            steps {
                lint()
            }
        }

        // Stage: Scan the image for vulnerabilities
        stage('Scan') {
            steps {
                echo 'Skipping vulnerability scan due to compatibility issues.'
                // vulnerabilityScan()
            }
        }

        // Stage: Run OpenSCAP compliance scan (conditional)
        stage('SCAP-Scan') {
            when {
                    expression { return params.SCAP_SCAN }
            }
            steps {
                scapScan()
            }
        }

        // Stage: Run container structure tests (conditional)
        stage('Structure-Tests') {
            when {
                expression { return params.TEST_STRUCTURE }
            }
            steps {
                structureTests()
            }
        }

        // Stage: Run Docker functional tests (conditional)
        stage('Docker-Run-Tests') {
            when {
                expression { return params.DOCKER_TESTS }
            }
            steps {
                dockerTests()
            }
        }

        // Stage: Publish image to internal registries (conditional)
        stage('Publish-Image') {
            when {
                    anyOf {
                        branch 'develop'
                        expression { return params.PUBLISH_IMAGE }
                    }
            }
            steps {
                publishToInternalRegistry()
                // Trigger downstream QA image build job
                build job: 'KubeNinjas/docker/docker-nightly-builds-qa', wait: false, parameters: [string(name: 'dockerImageType', value: "${dockerImageType}"), string(name: 'marklogicVersion', value: "${RPMversion}")]
            }
        }

        // Stage: Trigger BlackDuck security scan (conditional)
        stage('BlackDuck-Scan') {
            when {
                anyOf {
                        branch 'develop'
                        expression { return params.PUBLISH_IMAGE }
                    }
            }
            steps {
                scanWithBlackDuck()
            }
        }

    }

    post {
        always {
            // Clean up the workspace and Docker resources
            sh '''
                cd src
                rm -rf *.rpm NOTICE.txt
                docker stop $(docker ps -a -q) || true
                docker system prune --force --all --volumes
                docker system df
            '''
            publishTestResults()
        }
        success {
            resultNotification('✅ Success')
        }
        failure {
            resultNotification('❌ Failure')
        }
        unstable {
            resultNotification('⚠️ Unstable')
        }
        aborted {
            resultNotification('🚫 Aborted')
        }
            }
}
