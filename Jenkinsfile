// This Jenkinsfile defines internal MarkLogic build pipeline.
// TODO: Before publishing, update git URL, remove commented code

// Import libraries
@Library('shared-libraries') _
import groovy.json.JsonSlurperClassic

// Define local variables
//githubAPIUrl="https://api.github.com/repos/vitalykorolev/marklogic-docker-fork"
gitCredID = '550650ab-ee92-4d31-a3f4-91a11d5388a3'

// Define local funtions
void PreBuildCheck() {
	echo 'Initialize parameters as environment variables due to https://issues.jenkins-ci.org/browse/JENKINS-41929'
	evaluate """${def script = ""; params.each { k, v -> script += "env.${k} = '''${v}'''\n" }; return script}"""

	if(params.BRANCH_OVERRIDE != ""){
		BRANCH_NAME = params.BRANCH_OVERRIDE
	}
	if(BRANCH_NAME == ''){
		echo "Branch name is empty!"
		sh 'exit 1'
	}
	echo "Branch name: " + BRANCH_NAME

	// Extract Jira ticket number from branch name
	
	JIRA_ID = (BRANCH_NAME =~ /CLD-[0-9]{3,4}/)[0][1]
	if(JIRA_ID == ''){
		echo "Jira ticket number is empty!"
		JIRA_ID = false
	}

	githubAPIUrl = REPO_URL.replace(".git","").replace("github.com","api.github.com/repos")
	echo "githubAPIUrl: " + githubAPIUrl

	// if((!env.CHANGE_TITLE.startsWith("CLD-"))){
	// 	sh 'exit 1' 
	// }
	// else {
	// 	JIRA_ID=env.CHANGE_TITLE.split(':')[0]
	// }
	// echo "JIRA_ID: " + JIRA_ID
	//echo "CHANGE_ID: " + CHANGE_ID
	//echo "CHANGE_TITLE: " + env.CHANGE_TITLE
	

 if(env.CHANGE_ID){

	if(PRDraftCheck()){ sh 'exit 1' }

	if(getReviewState().equalsIgnoreCase("CHANGES_REQUESTED")){
		 println(reviewState)
		 sh 'exit 1'
	}

	// if(!isChangeInUI() && isPRUITest()){env.NO_UI_TESTS=true}

	}
	def obj=new abortPrevBuilds();
 	obj.abortPrevBuilds();
	gitCheckout ".", REPO_URL, BRANCH_NAME, gitCredID
}

def PRDraftCheck(){
	withCredentials([usernameColonPassword(credentialsId: gitCredID, variable: 'Credentials')]) {
		PrObj= sh (returnStdout: true, script:'''
					 curl -u $Credentials  -X GET  '''+githubAPIUrl+'''/pulls/$CHANGE_ID
					 ''')
	}
	def jsonObj = new JsonSlurperClassic().parseText(PrObj.toString().trim())
	return jsonObj.draft
}

def getReviewState(){
	def reviewResponse;
	def commitHash;
	withCredentials([usernameColonPassword(credentialsId: gitCredID, variable: 'Credentials')]) {
		reviewResponse = sh (returnStdout: true, script:'''
							curl -u $Credentials  -X GET  '''+githubAPIUrl+'''/pulls/$CHANGE_ID/reviews
							 ''')
		 commitHash = sh (returnStdout: true, script:'''
						 curl -u $Credentials  -X GET  '''+githubAPIUrl+'''/pulls/$CHANGE_ID
						 ''')
	}
	def jsonObj = new JsonSlurperClassic().parseText(commitHash.toString().trim())
	def commit_id=jsonObj.head.sha
	println(commit_id)
	def reviewState=getReviewStateOfPR reviewResponse,2,commit_id ;
	return reviewState
}

def getServerPath(branchName) {
	if("10.1".equals(branchName)) {
		return "rh7v-10-tst-bld-1.eng.marklogic.com/b10_1";
	} else if ("11.0".equals(branchName)) {
		return "rh7v-i64-11-build/HEAD";
	} else if ("9.0".equals(branchName)) {
		return "rh7v-90-tst-bld-1.marklogic.com/b9_0"
	} else {    
		return "INVALID BRANCH";
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
		RPM = sh(returnStdout: true, script: "cd src/centos;file MarkLogic-*.rpm | cut -d: -f1").trim()
		CONVERTERS = sh(returnStdout: true, script: "cd src/centos;file MarkLogicConverters-*.rpm | cut -d: -f1").trim()
		mlVersion = sh(returnStdout: true, script: "echo ${RPM}|  awk -F \"MarkLogic-\" '{print \$2;}'  | awk -F \".x86_64.rpm\"  '{print \$1;}' ").trim()
		//def mlVersion = sh(returnStdout: true, script: "echo ${RPM}" ).trim()
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
	//TODO: we need to show the prompt with PR is for develop branch
	// ultimately this still should trigger the job for server regression tests
	echo "Server regression tests"
	//input "Server regression tests need to be executed manually. "
}

def PublishToInternalRegestry() {
	withCredentials([usernamePassword(credentialsId: '8c2e0b38-9e97-4953-aa60-f2851bb70cc8', passwordVariable: 'docker_password', usernameVariable: 'docker_user')]) {
		            sh """
		                docker login -u ${docker_user} -p ${docker_password} ${dockerRegistry} 
		                cd src/centos
		                make push-mlregistry version=${mlVersion}-${env.platformString}-${env.dockerVersion} 
		            """
	}
}

pipeline{
	agent {
				label{
					label 'docker-vitaly';
				}
	}
	options {
		checkoutToSubdirectory '.'
		buildDiscarder logRotator(artifactDaysToKeepStr: '7', artifactNumToKeepStr: '', daysToKeepStr: '30', numToKeepStr: '')
	}
	environment {
		buildServer = "distro.marklogic.com"
		buildServerBasePath = "/space/nightly/builds/"
		buildServerPlatform = "linux64-rh7"
		buildServerPath = getServerPath(params.ML_SERVER_BRANCH)
		dockerRegistry="https://ml-docker-dev.marklogic.com"
	}

	parameters{
		string(name: 'failEmail', defaultValue: 'vkorolev@marklogic.com', description: 'Whom should I send the Pass email to?', trim: true)
		string(name: 'passEmail', defaultValue: 'vkorolev@marklogic.com', description: 'Whom should I send the Failure email to?', trim: true) 
		string(name: 'REPO_URL', defaultValue: 'https://github.com/vitalykorolev/marklogic-docker-fork.git', description: 'Docker repository URL', trim: true)
		string(name: 'dockerVersion', defaultValue: '1.0.0-ea4', description: 'ML Docker version. This version along with ML rpm package version will be the image tag as {ML_Version}_{dockerVersion}', trim: true)
		string(name: 'platformString', defaultValue: 'centos', description: 'Platform string for Docker image version. Will be made part of the docker image tag', trim: true)
		string(name: 'BRANCH_OVERRIDE', defaultValue: '', description: 'define branch for docker repo')
		choice(name: 'ML_SERVER_BRANCH', choices: '10.1\n11.0\n9.0', description: 'MarkLogic Server Branch. used to pick appropriate rpm')
		string(name: 'ML_RPM', defaultValue: '', description: 'RPM to be used for Image creation. \n If left blank nightly ML rpm will be used.\n Please provide an accessible path e.g. /project/engineering or /project/qa', trim: true)
		string(name: 'ML_CONVERTERS', defaultValue: '', description: 'The Converters RPM to be included in the image creation \n If left blank the nightly ML Converters Package will be used.', trim: true)
		booleanParam(name: 'PUBLISH_IMAGE', defaultValue: false, description: 'Publish image to internal registry')
	}

	stages{
		stage('Pre-Build-Check'){
			steps{
				PreBuildCheck()
			}
			post{failure{postStage('Stage Failed')}}
		}

		stage("Copy-RPMs") {
			steps{
				//CopyRPMs()
				echo 'Copying RPMs'
			}
			post{failure{postStage('Stage Failed')}}
		}

		stage("Build-Image") {
			steps{
				echo 'Building Image'
				//sh "cd src/centos; make build version=${mlVersion}-${env.platformString}-${env.dockerVersion} package=${RPM} converters=${CONVERTERS}"
			}
			post{failure{postStage('Stage Failed')}}
		}

		stage("Image-Test") {
			steps{
				echo 'Running Image Tests'
				// RunStructureTests()
			}
			post{failure{postStage('Stage Failed')}}
		}

		stage("Run-Server-Regression-Tests") {
			steps{
				RunServerRegressionTests()
			}
			post{failure{postStage('Stage Failed')}}
		}

		stage("Publish-Image") {
			when{
					expression{ return params.PUBLISH_IMAGE }
			}
			steps{
				echo 'Publishing Image'
				//PublishToInternalRegistry()
			} 
		}

	}

	post {
		always {
				sh """
					cd src/centos
					rm -rf *.rpm
				"""
		}
		success {  
			mail bcc: '', body: "<b>Jenkins pipeline for ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br>${env.BUILD_URL}</b>", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "BUILD SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}", to: "${params.passEmail}";
			if(JIRA_ID){
				jiraAddComment comment: "Jenkins build was successful: ${BUILD_URL}", idOrKey: JIRA_ID, site: 'JIRA'
			}
		}  
		failure {  
			mail bcc: '', body: "<b>Jenkins pipeline for ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br>${env.BUILD_URL}</b>", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "BUILD ERROR: ${env.JOB_NAME} #${env.BUILD_NUMBER}", to: "${params.failEmail}";
			if(JIRA_ID){
				jiraAddComment comment: "Jenkins build failed: ${BUILD_URL}", idOrKey: JIRA_ID, site: 'JIRA'
			}
		}  
		unstable {  
			mail bcc: '', body: "<b>Jenkins pipeline for ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br>${env.BUILD_URL}</b>", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "BUILD UNSTABLE: ${env.JOB_NAME} #${env.BUILD_NUMBER}", to: "${params.failEmail}";
			if(JIRA_ID){

				jiraAddComment comment: "Jenkins build is unstable: ${BUILD_URL}", idOrKey: JIRA_ID, site: 'JIRA'
			}
		}   
	}
}
