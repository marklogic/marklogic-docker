// This Jenkinsfile defines internal MarkLogic build pipeline.

// Import libraries
@Library('shared-libraries') _
import groovy.json.JsonSlurperClassic

// Define local variables
githubAPIUrl="https://api.github.com/repos/marklogic/marklogic-ddocker"

// Define local funtions
void PreBuildCheck() {

 if(env.CHANGE_ID){

	if(PRDraftCheck()){ sh 'exit 1' }

	if((!env.CHANGE_TITLE.startsWith("CLD-")) && (!env.CHANGE_TITLE.startsWith("DEVO-"))){ sh 'exit 1' }

	if(getReviewState().equalsIgnoreCase("CHANGES_REQUESTED")){
		 println(reviewState)
		 sh 'exit 1'
	}

	// if(!isChangeInUI() && isPRUITest()){env.NO_UI_TESTS=true}

 }
 def obj=new abortPrevBuilds();
 obj.abortPrevBuilds();

}

def PRDraftCheck(){
	withCredentials([usernameColonPassword(credentialsId: '550650ab-ee92-4d31-a3f4-91a11d5388a3', variable: 'Credentials')]) {
		PrObj= sh (returnStdout: true, script:'''
					 curl -u $Credentials  -X GET  '''+githubAPIUrl+'''/pulls/$CHANGE_ID
					 ''')
	}
	def jsonObj = new JsonSlurperClassic().parseText(PrObj.toString().trim())
	return jsonObj.draft
}

def getReviewState(){
	def  reviewResponse;
	def commitHash;
	withCredentials([usernameColonPassword(credentialsId: '550650ab-ee92-4d31-a3f4-91a11d5388a3', variable: 'Credentials')]) {
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

void copyRPMs() {
	script {
		def timeStamp = sh(returnStdout: true, script: 'date +%Y%m%d').trim()
	}
	gitCheckout ".","${params.REPO_URL}","${params.REPO_BRANCH}", '550650ab-ee92-4d31-a3f4-91a11d5388a3'
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
	}
}
// Define Jenkins build pipeline
pipeline{
	agent {
				label{
					label 'docker-vitaly';
				}
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
		string(name: 'REPO_URL', defaultValue: 'https://github.com/marklogic/marklogic-docker.git', description: 'Docker repository URL', trim: true)
		string(name: 'dockerVersion', defaultValue: '1.0.0-ea3', description: 'ML Docker version. This version along with ML rpm package version will be the image tag as {ML_Version}_{dockerVersion}', trim: true)
		string(name: 'platformString', defaultValue: 'centos', description: 'Platform string for Docker image version. Will be made part of the docker image tag', trim: true)
		string(name: 'REPO_BRANCH', defaultValue: 'develop', description: 'branch for portal repo')
		choice(name: 'ML_SERVER_BRANCH', choices: '10.1\n11.0\n9.0', description: 'MarkLogic Server Branch. used to pick appropriate rpm')
		string(name: 'ML_RPM', defaultValue: '', description: 'RPM to be used for Image creation. \n If left blank nightly ML rpm will be used.\n Please provide an accessible path e.g. /project/engineering or /project/qa', trim: true)
		string(name: 'ML_CONVERTERS', defaultValue: '', description: 'The Converters RPM to be included in the image creation \n If left blank the nightly ML Converters Package will be used.', trim: true)
	}
	stages{
		stage('Pre-Build-Check'){
		steps{ PreBuildCheck() }
		post{failure{postStage('Stage Failed')}}
		}
		// check out build scripts and get MarkLogic RPM
		stage("Copy-RPMs") {
			steps{ copyRPMs() }
		}
		// build docker image
		// stage("build") {
		// 	steps{
		// 		sh """
		// 			cd src/centos
		// 			make build version=${mlVersion}-${env.platformString}-${env.dockerVersion} package=${RPM} converters=${CONVERTERS}
		// 		"""
		// 	}
		// }

		// test docker image and generate junit report
		// stage("test") {
		// 	steps{
		// 		sh """
		// 			cd test
		// 			#insert current version
		// 			sed -i -e 's/VERSION_PLACEHOLDER/${mlVersion}-${env.platformString}-${env.dockerVersion}/' ./structure-test.yml
		// 			curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 && chmod +x container-structure-test-linux-amd64 && mv container-structure-test-linux-amd64 container-structure-test
		// 			./container-structure-test test --config ./structure-test.yml --image marklogic-centos/marklogic-server-centos:${mlVersion}-${env.platformString}-${env.dockerVersion} --output junit | tee container-structure-test.xml
		// 			#fix junit output
		// 			sed -i -e 's/<\\/testsuites>//' -e 's/<testsuite>//' -e 's/<testsuites/<testsuite name="container-structure-test"/' ./container-structure-test.xml
		// 		"""
		// 		junit testResults: '**/container-structure-test.xml'
		// 	}
		// }

		// publish docker image to internal registry
		// stage("publish") {
		//     steps{
		//         withCredentials([usernamePassword(credentialsId: '8c2e0b38-9e97-4953-aa60-f2851bb70cc8', passwordVariable: 'docker_password', usernameVariable: 'docker_user')]) {
		//             sh """
		//                 docker login -u ${docker_user} -p ${docker_password} ${dockerRegistry} 
		//                 cd src/centos
		//                 make push-mlregistry version=${mlVersion}-${env.platformString}-${env.dockerVersion} 
		//             """
		//         }
		//     }    
		// }

		stage("clean") {
			steps{
				sh """
					cd src/centos
					rm -rf *.rpm
				"""
			}
		}
	}
	// post {
	// 	success {  
	// 		mail bcc: '', body: "<b>Jenkins pipeline for ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br>${env.BUILD_URL}</b>", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "BUILD SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}", to: "${params.passEmail}";
	// 	}  
	// 	failure {  
	// 		mail bcc: '', body: "<b>Jenkins pipeline for ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br>${env.BUILD_URL}</b>", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "BUILD ERROR: ${env.JOB_NAME} #${env.BUILD_NUMBER}", to: "${params.failEmail}";
	// 	}  
	// 	unstable {  
	// 		mail bcc: '', body: "<b>Jenkins pipeline for ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br>${env.BUILD_URL}</b>", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "BUILD UNSTABLE: ${env.JOB_NAME} #${env.BUILD_NUMBER}", to: "${params.failEmail}";
	// 	}   
	// }
}
