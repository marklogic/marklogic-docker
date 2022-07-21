*** Settings ***
Library   Process
Library   String
Library   OperatingSystem
Library   RequestsLibrary

*** Variables ***
@{DOCKER DEFAULTS}  -it  -d  -p  8000:8000  -p  8001:8001  -p  8002:8002  -p7997:7997
${DEFAULT ADMIN USER}  test_admin
${DEFAULT ADMIN PASS}  test_admin_pass
${TEST_IMAGE}  %{DOCKER_TEST_IMAGE=marklogic-centos/marklogic-server-centos:10-internal}
${DOCKER TIMEOUT}  90s
${LICENSE KEY}  %{QA_LICENSE_KEY=none}
${LICENSEE}  MarkLogic - Version 9 QA Test License

*** Keywords ***
Create container with
  [Arguments]  @{input parameters}
  [Documentation]  Use Docker run to create a single container with defined defaults and input parameters.
  ...              Container is named based on test case so that the same name can be used in cleanup.
  ...              Also verifies that the container is up by checking Docker logs.
  ${container name}=  Remove spaces from  ${TEST NAME}
  Run Process  docker  run  @{DOCKER DEFAULTS}  @{input parameters}  --name  ${container name}  ${TEST_IMAGE}  stderr=test_results/stderr-${container name}.txt  stdout=test_results/stdout-${container name}.txt  timeout=${DOCKER TIMEOUT}
  File Should Be Empty  test_results/stderr-${container name}.txt
  Docker log should contain  *Cluster config complete, marking this node as ready.*

Create failing container with
  [Arguments]  @{input parameters}
  [Documentation]  Creates Docker container without verifying its status. Used for negative tests.
  ${container name}=  Remove spaces from  ${TEST NAME}
  Run Process  docker  run  @{DOCKER DEFAULTS}  @{input parameters}  --name  ${container name}  ${TEST_IMAGE}  stderr=test_results/stderr-${container name}.txt  stdout=test_results/stdout-${container name}.txt  timeout=${DOCKER TIMEOUT}


Create second container with
  [Documentation]  NOT USED. Creates a second container for testing.
  ...              TODO: still need to figure out how to id the second container in tests and cleanup. 
  [Arguments]  @{input parameters}
  ${container name}=  Remove spaces from  ${TEST NAME}
  Run Process  docker  run  @{DOCKER DEFAULTS}  @{input parameters}  --name  ${container name}-2  ${TEST_IMAGE}  stderr=test_results/stderr-${container name}-2.txt  stdout=test_results/stdout-${container name}-2.txt  timeout=${DOCKER TIMEOUT}
  File Should Be Empty  test_results/stderr-${container name}-2.txt
  Docker log should contain  *Cluster config complete, marking this node as ready.*

Delete container
  [Documentation]  Delete Docker container that is named the same as the test case.
  ${container name}=  Remove spaces from  ${TEST NAME}
  Run Process  docker  rm  -f  -v  ${container name}  timeout=${DOCKER TIMEOUT}

Start compose from
  [Arguments]  ${compose path}
  [Documentation]  Creates Docker compose stack based on yaml path.
  ...              Yaml file is copied to current directory for easier access.
  ...              Yaml file is updated with new image label and credentials.
  ...              Container status is verified using Docker logs.
  ${dir}  ${new path}=  Split Path  ${compose path}
  ${compose name}=  Set Variable  ${new path}
  ${new path}=  Set Variable  test_results/${new path}
  ${compose file}=  Get File  ${compose path}
  ${compose file}=  Replace String Using Regexp  ${compose file}  image:.*  image: ${TEST_IMAGE}
  ${compose file}=  Replace String Using Regexp  ${compose file}  MARKLOGIC_ADMIN_USERNAME=.*  MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
  ${compose file}=  Replace String Using Regexp  ${compose file}  MARKLOGIC_ADMIN_PASSWORD=.*  MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}

  Create File  ${new path}  ${compose file}
  Create File  test_results/mldb_admin_username.txt  ${DEFAULT ADMIN USER}
  Create File  test_results/mldb_admin_password.txt  ${DEFAULT ADMIN PASS}
  Run Process  docker  compose  -f  ${new path}  up  -d  --no-color  stderr=test_results/stderr-${compose name}.txt  stdout=test_results/stdout-${compose name}.txt  timeout=${DOCKER TIMEOUT}
  
  #get a list of nodes from compose and check readyness for each
  ${result}=  Run Process  docker  compose  -f  ${compose file}  ps  --services
  @{nodes}=  Split to lines  ${result.stdout}
  FOR    ${node}    IN    @{nodes}
    ${node}=   Get Variable Value  ${node}
    Compose logs should contain  ${new path}  *${node}*Cluster config complete, marking this node as ready.*
  END

Delete compose from
  [Arguments]  ${compose path}
  [Documentation]  Delete compose stack identified with yaml path.
  ${dir}  ${new path}=  Split Path  ${compose path}
  ${new path}=  Set Variable  test_results/${new path}
  Remove Files  mldb_admin_username.txt  mldb_admin_password.txt
  Run Process    docker  compose  -f  ${new path}  down  -v

Restart compose from
  [Arguments]  ${compose path}
  [Documentation]  Restarts compose stack identified with yaml path.
  ${dir}  ${new path}=  Split Path  ${compose path}
  ${new path}=  Set Variable  test_results/${new path}
  Run Process    docker  compose  -f  ${new path}  restart

Docker log should contain
  [Arguments]  ${string pattern}
  [Documentation]  Wrapper keyword that reties Get container log message
  Wait Until Keyword Succeeds  ${DOCKER TIMEOUT}  10s  Get container log message  ${string pattern}

Get container log message
  [Arguments]  ${string pattern}
  [Documentation]  Get Docker logs for a current image and find a matching string based on input pattern.
  ${container name}=  Remove spaces from  ${TEST NAME}
  Run Process  docker  logs  ${container name}  stdout=test_results/stdout-${container name}.txt  timeout=${DOCKER TIMEOUT}
  ${docker log}=  Get File  test_results/stdout-${container name}.txt
  Should Match  ${docker log}  ${string pattern}  msg=Did not find ${string pattern} in ${container name} container log

Compose logs should contain
  [Arguments]  ${compose path}  ${string pattern}
  [Documentation]  Wrapper keywork that retries Get compose log message
  Wait Until Keyword Succeeds  ${DOCKER TIMEOUT}  10s  Get compose log message  ${compose path}  ${string pattern}

Get compose log message
  [Arguments]  ${compose path}  ${string pattern}
  [Documentation]  Get compose logs for a current stack and find a matching string based on input pattern.
  ${temp}  ${compose path}=  Split Path    ${compose path}
  ${compose name}=  Remove spaces from  ${compose path}
  ${compose path}=  Set Variable  test_results/${compose path}
  Run Process  docker  compose  -f  ${compose path}  logs  stdout=test_results/stdout-${compose name}.txt  timeout=${DOCKER TIMEOUT}
  ${compose log}=  Get File  test_results/stdout-${compose name}.txt
  Should Match  ${compose log}  ${string pattern}  msg=Did not find ${string pattern} in ${compose name} compose logs

Remove spaces from
  [Arguments]  ${input string}
  [Documentation]  Simple wrapper keyword for replace string
  ${output string}=  Replace String  ${input string}  ${SPACE}  ${EMPTY}
  [Return]  ${output string}

Generate digest authorization for
  [Arguments]  ${username}  ${password}
  [Documentation]  Generate digest header for a specified user
  ${bytes}=  Convert To Bytes  ${username}:${password}
  ${base64 encoded}=  Evaluate  base64.b64encode($bytes)  base64
  ${auth}=  Evaluate  ("${username}", "${password}")
  ${headers}=  Create Dictionary  Authorization=Basic ${base64 encoded}
  [Return]  ${auth}  ${headers}

Verify response for unauthenticated request with
  [Arguments]  ${port}  ${pattern}
  [Documentation]  Wrapper keyword that retries Check response message without credentials
  Wait Until Keyword Succeeds  ${DOCKER TIMEOUT}  10s  Check response message without credentials  ${port}  ${pattern}

Check response message without credentials
  [Arguments]  ${port}  ${pattern}
  [Documentation]  Sends GET request without credentials and looks for a matching pattern in response
  ${response}=  GET  url=http://localhost:${port}  expected_status=Anything
  Should Match  ${response.text}  ${pattern}  msg=Response from server did not include ${pattern} on port ${port}

Verify response for authenticated request with
  [Arguments]  ${port}  ${pattern}
  [Documentation]  Wrapper keyword that retries Check response message with credentials
  Wait Until Keyword Succeeds  ${DOCKER TIMEOUT}  10s  Check response message with credentials  ${port}  ${pattern}

Check response message with credentials
  [Arguments]  ${port}  ${pattern}
  [Documentation]  Sends GET request with credentials and looks for a matching pattern in response
  ${auth}  ${headers}=  Generate digest authorization for  ${DEFAULT ADMIN USER}  ${DEFAULT ADMIN PASS}
  ${response}=  Create Digest Session  RestSession  url=http://localhost:${port}  headers=${headers}  auth=${auth}
  ${response}=  GET On Session  RestSession  url=http://localhost:${port}  expected_status=Anything
  Should Match  ${response.text}  ${pattern}  msg=Response from server did not include ${pattern} on port ${port}

Host count on port ${port} should be ${count}
  [Documentation]  Wrapper keyword that retries Check host count on port ${port} should be ${count}
  Wait Until Keyword Succeeds  ${DOCKER TIMEOUT}  10s  Check host count on port ${port} should be ${count}

Check host count on port ${port} should be ${count}
  [Documentation]  Uses manange endpoint to get the number of hosts in a cluster and matches it against input number
  ${count}=  Convert To Integer  ${count}
  ${auth}  ${headers}=  Generate digest authorization for  ${DEFAULT ADMIN USER}  ${DEFAULT ADMIN PASS}
  ${response}=  Create Digest Session  RestSession  url=http://localhost:${port}  headers=${headers}  auth=${auth}
  ${response}=  GET On Session  RestSession  url=http://localhost:${port}/manage/v2/hosts?view=status&format=json
  ${host count}=  Set Variable  ${response.json()['host-status-list']['status-list-summary']['total-hosts']['value']} 
  Should Be Equal  ${host count}  ${count}
  #cluster hosts:
  #${response.json()['host-status-list']['status-list-items']['status-list-item']}
  