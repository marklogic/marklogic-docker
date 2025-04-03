*** Settings ***
Library    Process
Library    String
Library    OperatingSystem
Library    RequestsLibrary
Library    Collections
Library    DateTime

*** Variables ***
@{DOCKER DEFAULTS}    -it    -d    -p    8000:8000    -p    8001:8001    -p    8002:8002    -p7997:7997    --platform    linux/amd64
${DEFAULT ADMIN USER}    test_admin
${DEFAULT ADMIN PASS}    test_admin_pass
${SPEC CHARS ADMIN PASS}    Admin@2$s%^&*!
${TEST_IMAGE}    %{DOCKER_TEST_IMAGE=progressofficial/marklogic-db:11.3.1-ubi-rootless-2.1.2}
${UPGRADE_TEST_IMAGE}    progressofficial/marklogic-db:11.3.1-ubi-rootless-2.1.2
${DOCKER TIMEOUT}    240s
${LICENSE KEY}    %{QA_LICENSE_KEY=none}
${LICENSEE}    MarkLogic - Version 9 QA Test License
${MARKLOGIC_VERSION}    11.3.1
${BUILD_BRANCH}    release_2.1.2
${IMAGE_TYPE}    ubi-rootless
${VOL_NAME}    MarkLogic_vol_1
${VOL_INFO}    src=${VOL_NAME},dst=/var/opt/MarkLogic
${MARKLOGIC_DOCKER_VERSION}    2.1.2

*** Keywords ***
Create container with
    [Arguments]    @{input parameters}
    [Documentation]    Use Docker run to create a single container with defined defaults and input parameters.
    ...                Container is named based on test case so that the same name can be used in cleanup.
    ...                Also verifies that the container is up by checking Docker logs.
    ${container name}=    Remove spaces from    ${TEST NAME}
    Run Process    docker    run    @{DOCKER DEFAULTS}    @{input parameters}    
    ...            --name    ${container name}    
    ...            ${TEST_IMAGE}    stderr=test_results/stderr-${container name}.txt    
    ...            stdout=test_results/stdout-${container name}.txt    
    ...            timeout=${DOCKER TIMEOUT}
    File Should Be Empty    test_results/stderr-${container name}.txt
    Docker log should contain    *Cluster config complete, marking this container as ready.*

Create failing container with
    [Arguments]    @{input parameters}
    [Documentation]    Creates Docker container without verifying its status. Used for negative tests.
    ${container name}=    Remove spaces from    ${TEST NAME}
    Run Process    docker    run    @{DOCKER DEFAULTS}    @{input parameters}    
    ...            --name    ${container name}    ${TEST_IMAGE}    
    ...            stderr=test_results/stderr-${container name}.txt    
    ...            stdout=test_results/stdout-${container name}.txt    
    ...            timeout=${DOCKER TIMEOUT}

Create test container with
    [Arguments]    @{input parameters}
    [Documentation]    Creates a test container for upgrade testing.
    ${container name}=    Remove spaces from    ${TEST NAME}
    Run Process    docker    run    @{DOCKER DEFAULTS}    @{input parameters}    
    ...            --name    ${container name}
    ...            --mount    ${VOL_INFO}    ${TEST_IMAGE} 
    ...            stderr=test_results/stderr-${container name}.txt    
    ...            stdout=test_results/stdout-${container name}.txt    
    ...            timeout=${DOCKER TIMEOUT}
    File Should Be Empty    test_results/stderr-${container name}.txt
    Docker log should contain    *Cluster config complete, marking this container as ready.*

Create upgrade container with
    [Arguments]    @{input parameters}
    [Documentation]    Creates a second test container for upgrade testing.
    ${container name}=    Remove spaces from    ${TEST NAME}
    Run Process    docker    run    @{DOCKER DEFAULTS}    @{input parameters}    
    ...            --name    ${container name}-2
    ...            --mount    ${VOL_INFO}    ${UPGRADE_TEST_IMAGE}  
    ...            stderr=test_results/stderr-${container name}-2.txt    
    ...            stdout=test_results/stdout-${container name}-2.txt    
    ...            timeout=${DOCKER TIMEOUT}
    File Should Be Empty    test_results/stderr-${container name}-2.txt
    Docker log should contain    *Cluster config complete, marking this container as ready.*    True

Stop container
    [Documentation]    Stop Docker container that is named the same as the test case.
    ${container name}=    Remove spaces from    ${TEST NAME}
    Run Process    docker    stop    ${container name}    timeout=${DOCKER TIMEOUT}

Delete container
    [Arguments]    ${second container}=False
    [Documentation]    Delete Docker container that is named the same as the test case.
    ${container name}=    Remove spaces from    ${TEST NAME}
    Run Process    docker    rm    -f    -v    ${container name}    timeout=${DOCKER TIMEOUT}
    IF    ${second container} == True
        Run Process    docker    rm    -f    -v    ${container name}-2    timeout=${DOCKER TIMEOUT}
    END

Delete volume
    [Documentation]    Delete Docker volume.
    Run Process    docker    volume    rm    ${VOL_NAME}    timeout=${DOCKER TIMEOUT}

Start compose from
    [Arguments]    ${compose path}    ${password}=${DEFAULT ADMIN PASS}    ${readiness}=True
    [Documentation]    Creates Docker compose stack based on yaml path.
    ...                            Yaml file is copied to current directory for easier access.
    ...                            Yaml file is updated with new image label and credentials.
    ...                            Container status is verified using Docker logs.
    ${dir}    ${new path}=    Split Path    ${compose path}
    ${compose name}=    Set Variable    ${new path}
    ${new path}=    Set Variable    test_results/${new path}
    ${compose file}=    Get File    ${compose path}
    ${compose file}=    Replace String Using Regexp    ${compose file}    image:.*    image: ${TEST_IMAGE}
    ${compose file}=    Replace String Using Regexp    ${compose file}    MARKLOGIC_ADMIN_USERNAME=.*    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ${compose file}=    Replace String Using Regexp    ${compose file}    MARKLOGIC_ADMIN_PASSWORD=.*    MARKLOGIC_ADMIN_PASSWORD=${password}
    ${compose file}=    Replace String    ${compose file}    $    $$

    Create File    ${new path}    ${compose file}
    Create File    test_results/mldb_admin_username.txt    ${DEFAULT ADMIN USER}
    Create File    test_results/mldb_admin_password.txt    ${password}
    Run Process    docker    compose    -f    ${new path}    up    -d    --no-color    
    ...            stderr=test_results/stderr-${compose name}.txt    
    ...            stdout=test_results/stdout-${compose name}.txt    
    ...            timeout=${DOCKER TIMEOUT}
    
    #get a list of nodes from compose and check readyness for each
    IF    ${readiness} == True
        ${result}=    Run Process    docker    compose    -f    ${new path}    ps    --services
        @{nodes}=    Split to lines    ${result.stdout}
        IF    @{nodes} == []    Fail    No containers detected in ${new path}!
        FOR        ${node}        IN        @{nodes}
            ${node}=     Get Variable Value    ${node}
            Compose logs should contain    ${new path}    *${node}*Cluster config complete, marking this container as ready.*
        END
    END

Delete compose from
    [Arguments]    ${compose path}
    [Documentation]    Delete compose stack identified with yaml path.
    ${dir}    ${new path}=    Split Path    ${compose path}
    ${new path}=    Set Variable    test_results/${new path}
    Remove Files    mldb_admin_username.txt    mldb_admin_password.txt
    Run Process        docker    compose    -f    ${new path}    down    -v

Restart compose from
    [Arguments]    ${compose path}
    [Documentation]    Restarts compose stack identified with yaml path.
    ${dir}    ${new path}=    Split Path    ${compose path}
    ${new path}=    Set Variable    test_results/${new path}
    Run Process        docker    compose    -f    ${new path}    restart

Docker log should contain
    [Arguments]    ${string pattern}    ${second container}=False
    [Documentation]    Wrapper keyword that reties Get container log message, set second argument to True get logs of second container.
    Wait Until Keyword Succeeds    ${DOCKER TIMEOUT}    10s    Get container log message    ${string pattern}    ${second container}

Get container log message
    [Arguments]    ${string pattern}    ${second container}=False
    [Documentation]    Get Docker logs for a current image and find a matching string based on input pattern, set second argument to True get logs of second container.
    ${container name}=    Remove spaces from    ${TEST NAME}
    IF    ${second container} == True
         ${container name}=    Set Variable    ${container name}-2
    END
    Run Process    docker    logs    ${container name}    stdout=test_results/stdout-${container name}.txt    timeout=${DOCKER TIMEOUT}
    ${docker log}=    Get File    test_results/stdout-${container name}.txt
    Should Match    ${docker log}    ${string pattern}    msg=Did not find ${string pattern} in ${container name} container log

MarkLogic Error log should contain
    [Arguments]    ${string pattern}
    [Documentation]    Wrapper keyword that reties Get container log message
    Wait Until Keyword Succeeds    ${DOCKER TIMEOUT}    10s    Get marklogic error log message    ${string pattern}

Get marklogic error log message
    [Arguments]    ${string pattern}
    [Documentation]    Get MarkLogic logs for a current image and find a matching string based on input pattern.
    ${container name}=    Remove spaces from    ${TEST NAME}
    ${marklogic log}=    Run    docker exec ${container name} cat /var/opt/MarkLogic/Logs/ErrorLog.txt
    Should Match Regexp    ${marklogic log}    ${string pattern}    msg=Did not find ${string pattern} in ${container name} container log

Verify converter package installation
    [Documentation]    Verify that the converters package is installed in the MarkLogic container.
    ...                This is done by checking the /opt/MarkLogic directory for the presence of the Converters directory.
    ${container name}=    Remove spaces from    ${TEST NAME}
    ${output}=    Run    docker exec ${container name} ls /opt/MarkLogic/
    Should Contain    ${output}    Converters
    
Compose logs should contain
    [Arguments]    ${compose path}    ${string pattern}
    [Documentation]    Wrapper keywork that retries Get compose log message
    Wait Until Keyword Succeeds    ${DOCKER TIMEOUT}    10s    Get compose log message    ${compose path}    ${string pattern}

Get compose log message
    [Arguments]    ${compose path}    ${string pattern}
    [Documentation]    Get compose logs for a current stack and find a matching string based on input pattern.
    ${temp}    ${compose path}=    Split Path        ${compose path}
    ${compose name}=    Remove spaces from    ${compose path}
    ${compose path}=    Set Variable    test_results/${compose path}
    Run Process    docker    compose    -f    ${compose path}    logs    
    ...            stdout=test_results/stdout-${compose name}.txt    
    ...            timeout=${DOCKER TIMEOUT}
    ${compose log}=    Get File    test_results/stdout-${compose name}.txt
    Should Match    ${compose log}    ${string pattern}    msg=Did not find ${string pattern} in ${compose name} compose logs

Remove spaces from
    [Arguments]    ${input string}
    [Documentation]    Simple wrapper keyword for replace string
    ${output string}=    Replace String    ${input string}    ${SPACE}    ${EMPTY}
    RETURN    ${output string}

Generate digest authorization for
    [Arguments]    ${username}    ${password}
    [Documentation]    Generate digest header for a specified user
    ${bytes}=    Convert To Bytes    ${username}:${password}
    ${base64 encoded}=    Evaluate    base64.b64encode($bytes)    base64
    ${auth}=    Evaluate    ("${username}", "${password}")
    ${headers}=    Create Dictionary    Authorization=Basic ${base64 encoded}
    RETURN    ${auth}    ${headers}

Verify response for unauthenticated request with
    [Arguments]    ${port}    ${pattern}
    [Documentation]    Wrapper keyword that retries Check response message without credentials
    Wait Until Keyword Succeeds    ${DOCKER TIMEOUT}    10s    Check response message without credentials    ${port}    ${pattern}

Check response message without credentials
    [Arguments]    ${port}    ${pattern}
    [Documentation]    Sends GET request without credentials and looks for a matching pattern in response
    ${response}=    GET    url=http://localhost:${port}    expected_status=Anything
    Should Match    ${response.text}    ${pattern}    msg=Response from server did not include ${pattern} on port ${port}

Verify response for authenticated request with
    [Arguments]    ${port}    ${pattern}    ${password}=${DEFAULT ADMIN PASS}
    [Documentation]    Wrapper keyword that retries Check response message with credentials
    Wait Until Keyword Succeeds    ${DOCKER TIMEOUT}    10s    Check response message with credentials    ${port}    ${pattern}    ${password}

Check response message with credentials
    [Arguments]    ${port}    ${pattern}    ${password}
    [Documentation]    Sends GET request with credentials and looks for a matching pattern in response
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${password}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    GET On Session    RestSession    url=http://localhost:${port}    expected_status=Anything
    Should Match    ${response.text}    ${pattern}    msg=Response from server did not include ${pattern} on port ${port}

Host count on port ${port} should be ${count}
    [Documentation]    Wrapper keyword that retries Check host count on port ${port} should be ${count}
    Wait Until Keyword Succeeds    ${DOCKER TIMEOUT}    10s    Check host count on port ${port} should be ${count}

Check host count on port ${port} should be ${count}
    [Documentation]    Uses manange endpoint to get the number of hosts in a cluster and matches it against input number
    ${count}=    Convert To Integer    ${count}
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    GET On Session    RestSession    url=http://localhost:${port}/manage/v2/hosts?view=status&format=json
    ${host count}=    Set Variable    ${response.json()['host-status-list']['status-list-summary']['total-hosts']['value']} 
    Should Be Equal    ${host count}    ${count}
    #cluster hosts:
    #${response.json()['host-status-list']['status-list-items']['status-list-item']}

Host ${hostname} should be part of group ${group}
    [Documentation]    Wrapper keyword that retries Check host ${hostname} should be in group ${group}
    Wait Until Keyword Succeeds    ${DOCKER TIMEOUT}    20s    Check host ${hostname} should be in group ${group}

Add group ${group} on host on port ${port}
    [Documentation]    Uses manange endpoint to add a group in a cluster
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Content-type=application/json 
    ${body}=    Create Dictionary    group-name=enode     
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    POST On Session    RestSession    url=http://localhost:${port}/manage/v2/groups    json=${body}
    ${response}=    GET On Session    RestSession    url=http://localhost:${port}/manage/v2/groups?format=json
    
Check host ${hostname} should be in group ${group}
    [Documentation]    Uses manange endpoint to get the group information of host in a cluster and matches it against input group
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:7102    headers=${headers}    auth=${auth}
    ${response}=    GET On Session    RestSession    url=http://localhost:7102/manage/v2/hosts/${hostname}/properties?format=json
    ${host group}=    Set Variable    ${response.json()['group']} 
    Should Be Equal    ${host group}    ${group}

Add certificate template on bootstrap host
    [Arguments]    ${certtemplate path}    ${port}
    [Documentation]    Uses manange endpoint to add a certificate template on a bootstrap host
    ${dir}    ${newfile}=    Split Path    ${certtemplate path}
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Content-Type=application/json
    ${json_file}=    Set Variable    test_template.json
    ${json_data}=    Get File    ${json_file}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}    
    ${response}=    POST On Session    RestSession    url=http://localhost:${port}/manage/v2/certificate-templates    
    ...             data=${json_data}    headers=${header}
    ${response}=    GET On Session    RestSession    url=http://localhost:${port}/manage/v2/certificate-templates?format=json

Apply certificate ${templateName} on App Server ${appServer} ${port}
    [Documentation]    Uses manange endpoint to enable https on an AppSever in default group
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Content-type=application/json 
    ${body}=    Create Dictionary    ssl-certificate-template=testTemplate     
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    PUT On Session    RestSession    
    ...            url=http://localhost:${port}/manage/v2/servers/${appServer}/properties?group-id=Default    json=${body}

Get CAcertificate for ${templateName} ${port}
    [Documentation]    Uses eval endpoint to get the CA of Cert template
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Content-type=application/x-www-form-urlencoded     Accept=multipart/mixed    boundary=BOUNDARY
    ${xqy_data}=    Get File    get_ca_xquery.xqy
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}    disable_warnings=1
    ${response}=    POST On Session    RestSession    url=http://localhost:${port}/v1/eval?database=Security    data=${xqy_data}    headers=${header}
    ${resptext}=    Set Variable    ${response.text}
    ${sep}=    Set Variable    X-Path: /*:certificate/*:pem/text()
    ${regex}=    Set Variable    --(?=.*[a-zA-Z])(?=.*[0-9])[A-Za-z0-9]+--
    ${pre}    ${post}=    Split String    ${resptext}    ${sep}
    ${rest}=    Remove String Using Regexp    ${post}    ${regex}
    ${cert}=	Strip String    ${rest}
    Create File    test_results/certificate.cer    ${cert}

Create invalid certificate file
    ${invalid_cert}=    Set Variable    This is an invalid cert for testing negative scenarios
    Create File    test_results/certificate.cer    ${invalid_cert}

Convert timezone to MarkLogic offset
    [Documentation]    Converts time zone string (America/St_Johns) to MarkLogic quivalent offset (-PT3H30M)
    [Arguments]    ${TZ}

    Set Environment Variable    TZ    ${TZ}
    ${result}=    Run Process    date    +%-z
    ${offset}=    Set Variable    ${result.stdout}
    ${absolute_value} =    Evaluate    abs(${offset})
    ${hours} =    Evaluate    int(${absolute_value}/100)
    ${minutes} =    Evaluate    ${absolute_value}%100
    ${sign} =    Run Keyword If    ${offset} < 0    Set Variable    -    ELSE    Set Variable    ${EMPTY}
    ${ML offset} =    Run Keyword If    ${minutes} > 0    Set Variable    ${sign}PT${hours}H${minutes}M    
    ...                                       ELSE    Set Variable    ${sign}PT${hours}H
    RETURN    ${ML offset}

Verify container timezone
    [Arguments]    ${timezone}    ${port}=8000    ${password}=${DEFAULT ADMIN PASS}
    [Documentation]    Get time zone offset from MarkLogic via /v1/eval REST call.
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${password}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${body}=    Create Dictionary    javascript=fn.timezoneFromDateTime(fn.currentDateTime())
    ${response}=    POST On Session    RestSession    url=http://localhost:${port}/v1/eval    data=${body}
    ${offset}=    Get Regexp Matches    ${response.text}    -?PT[HM0-9]+
    ${expected}=    Convert timezone to MarkLogic offset    ${timezone}
    Should Be Equal    ${expected}    ${offset[0]}

Create dynamic host token for group ${group} on host ${host} and port ${port} using docker port ${dockerport} with duration ${duration} and comment ${comment}
    [Documentation]    This generate a dynamic host token that can be used for join purpose.
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Content-type=application/json
    ${port_num}=    Convert To Integer    ${port}
    ${token_details}=    Create Dictionary    group=${group}    host=${host}    port=${port_num}    duration=${duration}    comment=${comment}
    ${token_body}=    Create Dictionary    dynamic-host-token=${token_details}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${dockerport}    headers=${headers}    auth=${auth}
    ${response}=    POST On Session    RestSession    url=/manage/v2/clusters/Default/dynamic-host-token    json=${token_body}    headers=${header}
    ${token_xml}=    Set Variable    ${response.text}
    ${token_content}=    Get Regexp Matches    ${token_xml}    <dynamic-host-token[^>]*>(.*)</dynamic-host-token>    1
    ${token}=    Set Variable    ${token_content[0]}
    [Return]    ${token}

Enable dynamic host feature on ${dockerport} for group ${group}
    [Documentation]    This enables the dynamic host feature for the specified group.
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Content-type=application/json    Accept=application/json
    # Create JSON payload to enable dynamic hosts
    ${json_body}=    Create Dictionary    group-name=${group}    allow-dynamic-hosts=${TRUE}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${dockerport}    headers=${headers}    auth=${auth}
    ${response}=    PUT On Session    RestSession    url=/manage/v2/groups/${group}/properties?format=json    json=${json_body}    headers=${header}
    [Return]    ${response}

Disable dynamic host feature on ${dockerport} for group ${group}
    [Documentation]    This enables the dynamic host feature for the specified group.
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Content-type=application/json    Accept=application/json
    # Create JSON payload to enable dynamic hosts
    ${json_body}=    Create Dictionary    group-name=${group}    allow-dynamic-hosts=${FALSE}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${dockerport}    headers=${headers}    auth=${auth}
    ${response}=    PUT On Session    RestSession    url=/manage/v2/groups/${group}/properties?format=json    json=${json_body}    headers=${header}
    [Return]    ${response}

Init dynamic host ${dockerport} with token ${token}
    [Documentation]    This initializes the dynamic host with the specified token (no auth needed)
    ${header}=    Create Dictionary    Content-type=application/xml
    # Create XML payload with the token
    ${xml_body}=    Set Variable    <init xmlns="http://marklogic.com/manage"><dynamic-host-token>${token}</dynamic-host-token></init>
    
    # Use standard session without authentication
    Create Session    RestSession    url=http://localhost:${dockerport}
    ${response}=    POST On Session    RestSession    url=/admin/v1/init    data=${xml_body}    headers=${header}

Create group ${group} on port ${port}
    [Documentation]    Creates a new group in MarkLogic using the Management API
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Content-type=application/json    Accept=application/json
    ${json_body}=    Create Dictionary    group-name=${group}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    POST On Session    RestSession    url=/manage/v2/groups    json=${json_body}    headers=${header}

Set up dynamic host group ${group}
    Create group ${group} on port 7102
    # TODO: the enabling of the option on the Default group should be removed once the bug is fixed.
    Enable dynamic host feature on 7102 for group Default
    Enable dynamic host feature on 7102 for group ${group}

Get MarkLogic Host ID on port ${port} with hostname ${hostname}
    [Documentation]    Returns the host ID of a MarkLogic server with the specified hostname
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Accept=application/json
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    GET On Session    RestSession    url=/manage/v2/hosts?format=json    headers=${header}
    ${hosts}=    Set Variable    ${response.json()["host-default-list"]["list-items"]["list-item"]}
    ${host_id}=    Set Variable    ${EMPTY}
    FOR    ${host}    IN    @{hosts}
        IF    '${host["nameref"]}' == '${hostname}'
            ${host_id}=    Set Variable    ${host["idref"]}
            Exit For Loop
        END
    END
    
    Should Not Be Empty    ${host_id}    Host ${hostname} not found in the host list
    [Return]    ${host_id}

Get All Dynamic Host IDs on port ${port} for group ${group}
    [Documentation]    Gets all dynamic host IDs from the MarkLogic cluster
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Accept=application/json
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    GET On Session    RestSession    url=/manage/v2/clusters/${group}/dynamic-hosts?format=json    headers=${header}
    ${has_hosts}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${response.json()}    dynamic-hosts
    @{host_ids}=    Create List
    IF    ${has_hosts}
        ${hosts}=    Set Variable    ${response.json()["dynamic-hosts"]}
        ${host_ids}=    Set Variable    ${hosts}
    END
    [Return]    ${host_ids}

Remove All Dynamic Hosts on port ${port} for group ${group}
    [Documentation]    Removes all dynamic hosts from the MarkLogic cluster for a specific group
    @{host_ids}=    Get All Dynamic Host IDs on port ${port} for group ${group}
    ${host_count}=    Get Length    ${host_ids}
    IF    ${host_count} > 0
        ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
        ${header}=    Create Dictionary    Content-type=application/json    Accept=application/json
        ${dynamic_host_dict}=    Create Dictionary    dynamic-host=${host_ids}
        ${json_body}=    Create Dictionary    dynamic-hosts=${dynamic_host_dict}
        # Create session and send DELETE request
        ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
        ${response}=    DELETE On Session    RestSession
        ...            url=/manage/v2/clusters/${group}/dynamic-hosts
        ...            json=${json_body}
        ...            headers=${header}
        Log    Removed ${host_count} dynamic hosts from group ${group}
    ELSE
        Log    No dynamic hosts to remove from group ${group}
    END

Dynamic Host Join Successful on ${group} with ${port}
    ${token}=    Create dynamic host token for group ${group} on host bootstrap_3n and port 8001 using docker port 7102 with duration PT10M and comment no
    Init dynamic host ${port} with token ${token}

Dynamic Host Join Successful with d-node on ${group} with ${port}
    ${token}=    Create dynamic host token for group ${group} on host node2 and port 8001 using docker port 7102 with duration PT10M and comment no
    Init dynamic host ${port} with token ${token}

Dynamic Host Join Failure on ${group} with ${port} with wrong token
    [Documentation]    Tests that joining fails when token is corrupted
    ${token}=    Create dynamic host token for group ${group} on host bootstrap_3n and port 8001 using docker port 7102 with duration PT10M and comment no
    ${corrupted_token}=    Set Variable    ${token}XYZ123InvalidTokenSuffix
    ${status}=    Run Keyword And Return Status    Init dynamic host ${port} with token ${corrupted_token}
    Should Be Equal    ${status}    ${FALSE}    Join with corrupted token should have failed but succeeded

Dynamic Host Join Failure on ${group} with ${port} when feature disabled
    Disable dynamic host feature on 7102 for group ${group}
    ${token}=    Create dynamic host token for group ${group} on host bootstrap_3n and port 8001 using docker port 7102 with duration PT10M and comment no
    ${status}=    Run Keyword And Return Status    Init dynamic host ${port} with token ${token}
    Should Be Equal    ${status}    ${FALSE}    Join should fail when this feature is disabled
    Enable dynamic host feature on 7102 for group ${group}

Dynamic Host Join Failure on ${group} with ${port} when not using the Admin app server
    ${token}=    Create dynamic host token for group ${group} on host bootstrap_3n and port 8002 using docker port 7102 with duration PT10M and comment no
    ${status}=    Run Keyword And Return Status    Init dynamic host ${port} with token ${token}
    Should Be Equal    ${status}    ${FALSE}    Join should fail when this feature is disabled

Wait Until Container Is Stopped
    Sleep    50s

Wait Until Container Is Running
    Sleep    10s

Dynamic Host Remove Successful When Host is down
    Run Process    docker    kill    node2
    Wait Until Container Is Stopped
    Remove All Dynamic Hosts on port 7102 for group dynamic
    Run Process    docker    start    node2
    Wait Until Container Is Running
    @{host_ids}=    Get All Dynamic Host IDs on port 7202 for group dynamic
    Should Be Empty    ${host_ids}    Dynamic hosts were found when none were expected

Dynamic Host Remove Successful When All Node is up
    # sleep to make sure the host joins successfully
    Sleep    5s
    Remove All Dynamic Hosts on port 7102 for group dynamic
    @{host_ids}=    Get All Dynamic Host IDs on port 7102 for group dynamic
    Should Be Empty    ${host_ids}    Dynamic hosts were found when none were expected

Dynamic Host Added When Some Host is down ${port}
    Run Process    docker    kill    node2
    Wait Until Container Is Stopped
    Dynamic Host Join Successful on dynamic with ${port}
    Run Process    docker    start    node2
    Wait Until Container Is Running
    @{host_ids}=    Get All Dynamic Host IDs on port 7202 for group dynamic
    Should Not Be Empty    ${host_ids}    No dynamic hosts were found when some were expected

Dynamic Host Returns All Id ${container_name}
    Run Process    docker    kill    ${container_name}
    Wait Until Container Is Stopped
    @{host_ids}=    Get All Dynamic Host IDs on port 7202 for group dynamic
    ${host_count}=    Get Length    ${host_ids}
    Should Be Equal As Integers    ${host_count}    2    Expected exactly 2 dynamic hosts but found ${host_count}
    Run Process    docker    start    ${container_name}
    Wait Until Container Is Running

Verify Full Cluster Restart Removes Dynamic Host Configuration ${group}
    [Documentation]    Tests that restarting the entire cluster removes all dynamic host information

    @{host_ids}=    Get All Dynamic Host IDs on port 7102 for group dynamic
    ${host_count}=    Get Length    ${host_ids}
    Should Be Equal As Integers    ${host_count}    2    Expected 2 dynamic hosts but found ${host_count}
    
    # Restart the entire cluster
    Restart compose from    compose-test-16.yaml
    Sleep    30s

    # Verify dynamic host information is removed
    @{host_ids_after_restart}=    Get All Dynamic Host IDs on port 7102 for group dynamic
    Should Be Empty    ${host_ids_after_restart}    Dynamic hosts still exist after full cluster restart

Verify Dynamic Host Count on port ${port} for group ${group} equals ${expected_count}
    [Documentation]    Verifies that the number of dynamic hosts matches the expected count
    @{host_ids}=    Get All Dynamic Host IDs on port ${port} for group ${group}
    ${actual_count}=    Get Length    ${host_ids}
    ${expected_count}=    Convert To Integer    ${expected_count}
    Should Be Equal As Integers    ${actual_count}    ${expected_count}    
    ...    Expected ${expected_count} dynamic hosts but found ${actual_count}

    IF    ${actual_count} > 0
        Log    Found dynamic hosts: @{host_ids}
    END
    [Return]    ${host_ids}

Dynamic Host Join Fails When Token Expires ${group}
    [Documentation]    Tests that a token cannot be reused after it expires

    ${token}=    Create dynamic host token for group ${group} on host bootstrap_3n and port 8001 using docker port 7102 with duration PT5S and comment "short-lived token"
    Init dynamic host 8001 with token ${token}
    Sleep    10s    # Wait longer than the PT5S token duration
    ${status}=    Run Keyword And Return Status    Init dynamic host 8101 with token ${token}
    Should Be Equal    ${status}    ${FALSE}    Join succeeded with expired token when it should have failed
    Verify Dynamic Host Count on port 7102 for group ${group} equals 2

Dynamic Host Join Fails After Token Revoked ${group}
    [Documentation]    Tests that authentication fails after the token is revoked by the admin.

    ${token}=    Create dynamic host token for group ${group} on host bootstrap_3n and port 8001 using docker port 7102 with duration PT10M and comment "revoked token test"

    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Content-Type=application/xml
    ${xml_body}=    Set Variable    <dynamic-host-tokens><token>${token}</token></dynamic-host-tokens>
    ${response}=    Create Digest Session    RestSession    url=http://localhost:8002    headers=${headers}    auth=${auth}
    ${response}=    DELETE On Session    RestSession    url=/manage/v2/clusters/Default/dynamic-host-token    data=${xml_body}    headers=${header}

    ${status}=    Run Keyword And Return Status    Init dynamic host 8201 with token ${token}
    Should Be Equal    ${status}    ${FALSE}    Join succeeded with revoked token when it should have failed

Verify Dynamic Host Can Execute Query ${group} ${port}
    [Documentation]    Verifies that a dynamic host can execute a query using the REST API.

    # Execute a query to verify the dynamic host is functional
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Content-type=application/x-www-form-urlencoded
    ${query}=    Set Variable    xquery=xdmp:host-name(xdmp:host())
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    POST On Session    RestSession    url=/v1/eval    data=${query}    headers=${header}

    # Extract the host name from the response body
    ${host_name}=    Get Regexp Matches    ${response.text}    X-Primitive: string\r?\n\r?\n([^\r\n]+)    1
    Should Not Be Empty    ${host_name}    Query execution failed or returned an empty result
    Log    Dynamic host executed query successfully: ${host_name[0]}

Concurrent Dynamic Host Join Test
    [Documentation]    Tests joining multiple dynamic hosts concurrently and verifies all hosts were added
    [Arguments]    ${group}=dynamic    ${start_port}=7401    ${end_port}=8401
    
    
    # Create a list to store all tokens for concurrent joining
    ${token}=    Create dynamic host token for group ${group} on host bootstrap_3n and port 8001 using docker port 7102 with duration PT10M and comment "concurrent-test"
    
    FOR    ${port}    IN RANGE    ${start_port}    ${end_port}+100    100
        Init dynamic host ${port} with token ${token}
    END
    
    # Give some time for all operations to complete
    Sleep    10s
    
    # Verify the hosts were added - count how many were successful
    ${hosts}=    Get All Dynamic Host IDs on port 7102 for group ${group}
    ${host_count}=    Get Length    ${hosts}
    ${expected_count}=    Evaluate    (${end_port} - ${start_port}) / 100 + 1
    ${expected_count}=    Convert To Integer    ${expected_count}
    
    # Log the details
    Log    Found ${host_count} dynamic hosts from concurrent join
    Log    Expected approximately ${expected_count} dynamic hosts
    
    Should Be True    ${host_count} == ${expected_count}
