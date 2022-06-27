*** Settings ***
Documentation  These are docker and compose tests.
...            TODO add more
Library  Process
Library  String
Library  OperatingSystem
Library  RequestsLibrary
# Library  Collections
Resource  keywords.resource

*** Variables ***
@{DOCKER DEFAULTS}  -it  -d  -p  8000:8000  -p  8001:8001  -p  8002:8002  -p7997:7997
${DEFAULT ADMIN USER}  admin
${DEFAULT ADMIN PASS}  admin
# ${DOCKER IMAGE}  ml-docker-dev.marklogic.com/marklogic/marklogic-server-centos:10.1-20220618-centos-1.0.0-ea4
${DOCKER IMAGE}  ml-docker-dev.marklogic.com/marklogic/marklogic-server-centos:10.1-20220622-centos-1.0.0-ea4
${DOCKER TIMEOUT}  60s
${LICENSE KEY}  3981-CE27-75BB-9D3C-B81C-E067-1B39-DDFE-0875-C37E-D3F0-A76C-34E5-2F86-76BB-ADDD-E677-CB3F-D5FE-4773-C3CD-5EE8-87BC-36E5-3F71-0C15
${LICENSEE}  MarkLogic - Version 9 QA Test License

*** Keywords ***
Create container with
  [Arguments]  @{input parameters}
  ${container name}=  Remove spaces from  ${TEST NAME}
  Run Process  docker  run  @{DOCKER DEFAULTS}  @{input parameters}  --name  ${container name}  ${DOCKER IMAGE}  stderr=stderr-${container name}.txt  stdout=stdout-${container name}.txt  timeout=${DOCKER TIMEOUT}
  File Should Be Empty  stderr-${container name}.txt
  Docker log should contain  *Cluster config complete, marking node as ready*

Create second container with
  [Documentation]  Creates a second container for testing.
  ...              TODO: still need to figure out how to id the second container in tests. 
  [Arguments]  @{input parameters}
  ${container name}=  Remove spaces from  ${TEST NAME}
  Run Process  docker  run  @{DOCKER DEFAULTS}  @{input parameters}  --name  ${container name}-2  ${DOCKER IMAGE}  stderr=stderr-${container name}-2.txt  stdout=stdout-${container name}-2.txt  timeout=${DOCKER TIMEOUT}
  File Should Be Empty  stderr-${container name}-2.txt
  Docker log should contain  *Cluster config complete, marking node as ready*

Delete container
  #TODO search for other containers with the same prefix
  ${container name}  Remove spaces from  ${TEST NAME}
  Run Process  docker  rm  -f  -v  ${container name}  timeout=${DOCKER TIMEOUT}

Start compose from
  [Arguments]  ${compose path}
  ${dir}  ${new path}=  Split Path  ${compose path}
  ${compose file}=  Get File  ${compose path}
  ${compose file}=  Replace String Using Regexp  ${compose file}  image:.*  image: ${DOCKER IMAGE}
  ${compose file}=  Replace String Using Regexp  ${compose file}  MARKLOGIC_ADMIN_USERNAME=.*  MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
  ${compose file}=  Replace String Using Regexp  ${compose file}  MARKLOGIC_ADMIN_PASSWORD=.*  MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
  Create File  ${new path}  ${compose file}
  Create File  mldb_admin_username.txt  ${DEFAULT ADMIN USER}
  Create File  mldb_admin_password.txt  ${DEFAULT ADMIN PASS}
  Run Process  docker-compose  -f  ${new path}  up  -d  --no-color  stderr=stdout-${new path}.txt  stdout=stdout-${new path}.txt  timeout=${DOCKER TIMEOUT}
  #get a list of nodes from compose and check readyness for each
  ${result}=  Run Process  docker-compose  -f  ${compose file}  ps  --services
  @{nodes}=  Split to lines  ${result.stdout}
  FOR    ${node}    IN    @{nodes}
    ${node}=   Get Variable Value  ${node}
    Compose logs should contain  ${new path}  *${node}*Cluster config complete, marking node as ready*
  END

Delete compose from
  [Arguments]  ${compose path}
  ${dir}  ${new path}=  Split Path  ${compose path}
  Run Process    docker-compose  -f  ${new path}  down  -v

Restart compose from
  [Arguments]  ${compose path}
  ${dir}  ${new path}=  Split Path  ${compose path}
  Run Process    docker-compose  -f  ${new path}  restart

Docker log should contain
  [Arguments]  ${string pattern}
  Wait Until Keyword Succeeds  80 s  10 s  Get container log message  ${string pattern}

Get container log message
  [Arguments]  ${string pattern}
  ${container name}  Remove spaces from  ${TEST NAME}
  Run Process  docker  logs  ${container name}  stdout=stdout-${container name}.txt  timeout=${DOCKER TIMEOUT}
  ${docker log}=  Get File  stdout-${container name}.txt
  ${match}=  Get Lines Matching Pattern  ${docker log}  ${string pattern}
  IF  "${match}" == "${EMPTY}"
    Fail  "Did not find ${string pattern} in ${container name} container log"
  END

Compose logs should contain
  [Arguments]  ${compose path}  ${string pattern}
  Wait Until Keyword Succeeds  80 s  10 s  Get compose log message  ${compose path}  ${string pattern}

Get compose log message
  [Arguments]  ${compose path}  ${string pattern}
  ${temp}  ${compose path}=  Split Path    ${compose path}
  ${compose name}  Remove spaces from  ${compose path}
  Run Process  docker-compose  -f  ${compose path}  logs  stdout=stdout-${compose name}.txt  timeout=${DOCKER TIMEOUT}
  ${compose log}=  Get File  stdout-${compose name}.txt
  ${match}=  Get Lines Matching Pattern  ${compose log}  ${string pattern}
  IF  "${match}" == "${EMPTY}"
    Fail  "Did not find ${string pattern} in ${compose name} compose logs"
  END

Remove spaces from
  [Arguments]  ${input string}
  ${output string}=  Replace String  ${input string}  ${SPACE}  ${EMPTY}
  [Return]  ${output string}

Generate digest authorization for
  [Arguments]  ${username}  ${password}
  ${bytes}=  Convert To Bytes  ${username}:${password}
  ${base64 encoded}=  Evaluate  base64.b64encode($bytes)  base64
  ${auth}=  Evaluate  ("${username}", "${password}")
  ${headers}=  Create Dictionary  Authorization=Basic ${base64 encoded}
  [Return]  ${auth}  ${headers}

Verify response for unauthenticated request with
  [Arguments]  ${port}  ${pattern}
  ${response}=  GET  url=http://localhost:${port}  expected_status=Anything
  ${match}=  Get Lines Matching Pattern  ${response.text}  ${pattern}
  # ${match}=  Get Line  ${match}  0
  ${match}=  Get Substring    ${match}  start=0  end=10
  IF  "${match}" == "${EMPTY}"
    Fail  "Did not find ${pattern} in response on ${port}"
  END

Verify response for authenticated request with
  [Arguments]  ${port}  ${pattern}
  ${auth}  ${headers}=  Generate digest authorization for  ${DEFAULT ADMIN USER}  ${DEFAULT ADMIN PASS}
  ${response}=  Create Digest Session  RestSession  url=http://localhost:${port}  headers=${headers}  auth=${auth}
  ${response}=  GET On Session  RestSession  url=http://localhost:${port}  expected_status=Anything
  ${match}=  Get Lines Matching Pattern  ${response.text}  ${pattern}
  # ${match}=  Get Line  ${match}  0
  ${match}=  Get Substring    ${match}  start=0  end=10
  IF  "${match}" == "${EMPTY}"
    Fail  "Did not find ${pattern} in response on ${port}"
  END

Unauthenticated user should be forbidden on
  [Arguments]  ${port}
  Verify response for unauthenticated request with    ${port}    *Forbidden*

Unauthenticated user should be unauthorized on
  [Arguments]  ${port}
  Verify response for unauthenticated request with    ${port}    *Unauthorized*

Host count on port ${port} should be ${count}
  ${count}=  Convert To Integer  ${count}
  ${auth}  ${headers}=  Generate digest authorization for  ${DEFAULT ADMIN USER}  ${DEFAULT ADMIN PASS}
  ${response}=  Create Digest Session  RestSession  url=http://localhost:${port}  headers=${headers}  auth=${auth}
  ${response}=  GET On Session  RestSession  url=http://localhost:${port}/manage/v2/hosts?view=status&format=json
  ${host count}=  Set Variable  ${response.json()['host-status-list']['status-list-summary']['total-hosts']['value']} 
  Should Be Equal  ${host count}  ${count}

#cluster hosts:
#${response.json()['host-status-list']['status-list-items']['status-list-item']}