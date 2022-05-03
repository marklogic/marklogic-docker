// description
// dependencies
import groovy.json.JsonSlurper
import groovy.xml.XmlParser
import groovy.xml.XmlUtil
import groovy.cli.commons.CliBuilder

// Define test parameters
def testImage='marklogic-centos/marklogic-server-centos:10.0-20220128-centos-1.0.0-ea3-test'
def defaultParams='-it -d -p 8000:8000 -p 8001:8001 -p 8002:8002 -p7997:7997'
def curlCommand='curl -sL'
def curlCommandAuth='curl -sL --anyauth -u test_admin:test_admin_pass'
def composePath='./docker-compose/'
File jUnitReport = new File("docker-test-results.xml")
def xmlParser = new XmlParser()
def jsonSlurper = new JsonSlurper()
def jUnitXML = xmlParser.parseText("<testsuite/>")
jUnitXML.@name = "Docker Run Tests"

// Read test cases for Docker run and Docker Compose
File testCasesFile = new File("./test/docker-test-cases.json")
//testCasesFile.text = testCasesFile.text.replaceAll("LICENSE_PLACEHOLDER", "LICENSEE=ABC -e LICENSE_KEY=123")
def testCases = jsonSlurper.parseText(testCasesFile.text)
//validate JSON
assert testCases instanceof Map

if (args) {
	testImage = args[0]
}
println "Using ${testImage}"
def QA_LICENSE_KEY = System.getenv("QA_LICENSE_KEY")
if(QA_LICENSE_KEY) {
	println "QA_LICENSE_KEY is set to: ${QA_LICENSE_KEY}"
}
System.exit(1)

//create compose credential files
File usernameFile = new File("${composePath}mldb_admin_username.txt")
usernameFile.write("test_admin")
File passwordFile = new File("${composePath}mldb_admin_password.txt")
passwordFile.write("test_admin_pass")
def stdOut = new StringBuilder(), stdErr = new StringBuilder()
def ( totalTests, totalErrors ) = [ 0, 0 ]

// Run test cases
println "--------------------------------------------------------------------"
for ( test in testCases ) {
	println "Running "+test.key+": "+test.value.description
	def cmdOutput
	if ( test.value.params.toString().contains(".yml")) {
		println '[starting compose]'
		//update image label in yml file
		File file = new File(composePath + test.value.params)
		file.text = file.text.replaceFirst(/image: .*/, "image: "+testImage)
		cmdOutput = "docker-compose -f ${composePath}${test.value.params} up -d".execute()
	} else {
		println '[starting docker]'
		cmdOutput = "docker run ${defaultParams} ${test.value.params} ${testImage}".execute()
	}
	cmdOutput.consumeProcessOutput(stdOut, stdErr)
	cmdOutput.waitForOrKill(10000)
	//println "stdOut> $stdOut\nstdErr> $stdErr"
	if ( stdErr ) {
		println "ERROR: $stdErr"
		//TODO find a good way to skip the test on error
	} else {
		println stdOut
	}

	//TODO: Find a way to check for server status instead of a wait. (log: Database Modules is online)
	Thread.sleep(60000)
	def testCont = cmdOutput.text

	println "  Unauthenticated requests"
	for ( unauthTest in test.value.expected.unauthenticated ) {
		//TODO if key is 'log' then check for log message
		cmdOutput = "${curlCommand} http://localhost:${unauthTest.key}".execute()
		cmdOutput.waitFor()
		def jUnitTest = xmlParser.createNode( jUnitXML, "testcase", [assertions:1, time:0, name:"${test.value.description} on ${unauthTest.key} without credentials"] )
		totalTests += 1
		print "    Port ${unauthTest.key}: "
		if ( cmdOutput.text.contains(unauthTest.value) ) {
			println "passed"
		} else {
			println "failed"
			xmlParser.createNode(jUnitTest, "failure", [type:"Text mismatch", message:"Unexpected output"] )
			totalErrors += 1
		}
		Thread.sleep(1000)
	}

	println "  Authenticated requests"
	for ( authTest in test.value.expected.authenticated ) {
		cmdOutput = "${curlCommandAuth} http://localhost:${authTest.key}".execute()
		cmdOutput.waitFor()
		def jUnitTest = xmlParser.createNode( jUnitXML, "testcase", [assertions:1, time:0, name:"${test.value.description} on ${authTest.key} with credentials"] )
		totalTests += 1
		print "    Port ${authTest.key}: "
		if ( cmdOutput.text.contains(authTest.value) ) {
			println "passed"
		} else {
			println "failed"
			xmlParser.createNode(jUnitTest, "failure", [type:"Text mismatch", message:"Unexpected output"] )
			totalErrors += 1
		}
		Thread.sleep(1000)
	}

	println "[deleting resources]"
	if ( test.value.params.toString().contains(".yml")) {
		cmdOutput = "docker-compose -f ${composePath}${test.value.params} down".execute()
	} else {
		cmdOutput = "docker rm -f ${testCont}".execute()
	}
	cmdOutput.waitFor()
	cmdOutput = "docker prune -f ${testCont}".execute()
	cmdOutput.waitFor()
}
println "--------------------------------------------------------------------"

//capture test results in jUnit XML
jUnitXML.@tests = totalTests
jUnitXML.@assertions = totalTests
jUnitXML.@errors = totalErrors
jUnitXML.@failures = "0"
jUnitXML.@time = "0.0"
jUnitReport.write(XmlUtil.serialize(jUnitXML))
