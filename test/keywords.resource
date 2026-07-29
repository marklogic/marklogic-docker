# Copyright © 2018-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
*** Settings ***
Library    Process
Library    String
Library    OperatingSystem
Library    RequestsLibrary
Library    Collections
Library    DateTime

*** Variables ***
${DOCKER_PLATFORM}    %{DOCKER_PLATFORM=linux/amd64}
@{DOCKER DEFAULTS}    -it    -d    -p    8000:8000    -p    8001:8001    -p    8002:8002    -p7997:7997    --platform    ${DOCKER_PLATFORM}
${DEFAULT ADMIN USER}    test_admin
${DEFAULT ADMIN PASS}    test_admin_pass
${SPEC CHARS ADMIN PASS}    Admin@2$s%^&*!
${TEST_IMAGE}    %{DOCKER_TEST_IMAGE=progressofficial/marklogic-db:11.3.6-ubi-rootless-2.2.6}
${UPGRADE_TEST_IMAGE}    progressofficial/marklogic-db:${MARKLOGIC_VERSION}-${IMAGE_TYPE}-${MARKLOGIC_DOCKER_VERSION}
${DOCKER TIMEOUT}    300s
${LICENSE KEY}    %{QA_LICENSE_KEY=none}
${LICENSEE}    MarkLogic - Version 9 QA Test License
${MARKLOGIC_VERSION}    11.3.6
${BUILD_BRANCH}    release_2.2.6
${IMAGE_TYPE}    ubi-rootless
${VOL_NAME}    MarkLogic_vol_1
${VOL_INFO}    src=${VOL_NAME},dst=/var/opt/MarkLogic
${MARKLOGIC_DOCKER_VERSION}    2.2.6
${TEST_RESULTS_DIR}    test_results

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

Create container with latency
    [Arguments]    @{input parameters}
    [Documentation]    Use Docker run to create a single container with defined defaults and input parameters and simulated network latency.
    ...                Container is named based on test case so that the same name can be used in cleanup.
    ...                Also verifies that the container is up by checking Docker logs.
    ${container name}=    Remove spaces from    ${TEST NAME}
    Run Process    docker    run    @{DOCKER DEFAULTS}    @{input parameters}
    ...            --name    ${container name}
    ...            --cap-add    NET_ADMIN    --entrypoint    /bin/bash
    ...            ${TEST_IMAGE}
    ...            -c    sudo microdnf -y install iproute iptables && (sudo microdnf -y install iproute-tc || (sudo curl -fsS -O https://download.rockylinux.org/pub/rocky/8/BaseOS/x86_64/os/Packages/i/iproute-tc-6.2.0-6.el8_10.x86_64.rpm && sudo rpm -Uvh --replacepkgs iproute-tc-6.2.0-6.el8_10.x86_64.rpm)) && ((command -v tc >/dev/null && sudo tc qdisc add dev lo root netem delay 30000ms && sudo tc qdisc show dev lo) || ([ -x /usr/sbin/tc ] && sudo /usr/sbin/tc qdisc add dev lo root netem delay 30000ms && sudo /usr/sbin/tc qdisc show dev lo) || ([ -x /sbin/tc ] && sudo /sbin/tc qdisc add dev lo root netem delay 30000ms && sudo /sbin/tc qdisc show dev lo)) && /tini -- /usr/local/bin/start-marklogic.sh
    ...            stderr=test_results/stderr-${container name}.txt
    ...            stdout=test_results/stdout-${container name}.txt
    ...            timeout=15000
    File Should Be Empty    test_results/stderr-${container name}.txt
    Wait Until Keyword Succeeds    5 minutes    10s    Get container log message    *root refcnt 2 limit 1000 delay 30s*
    Wait Until Keyword Succeeds    30 minutes    30s    Get container log message    *Cluster config complete, marking this container as ready.*

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
    Skip If    'arm' in '${IMAGE_TYPE}'    msg=Skipping upgrade test for ARM image (no previous ARM upgrade image is available).
    Should Not Be Empty    ${UPGRADE_TEST_IMAGE}    msg=UPGRADE_TEST_IMAGE is empty; cannot run upgrade container.
    ${container name}=    Remove spaces from    ${TEST NAME}
    ${result}=    Run Process    docker    run    @{DOCKER DEFAULTS}    @{input parameters}    
    ...            --name    ${container name}-2
    ...            --mount    ${VOL_INFO}    ${UPGRADE_TEST_IMAGE}  
    ...            stderr=test_results/stderr-${container name}-2.txt    
    ...            stdout=test_results/stdout-${container name}-2.txt    
    ...            timeout=${DOCKER TIMEOUT}
    Should Be Equal As Integers    ${result.rc}    0
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
            ${node}=    Get Variable Value    ${node}
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

Docker log should NOT contain
    [Arguments]    ${string pattern}    ${second container}=False
    [Documentation]    Wrapper keyword that reties Get container log message with inversion, set second argument to True get logs of second container.
    Wait Until Keyword Succeeds    ${DOCKER TIMEOUT}    10s    Get container log message    ${string pattern}    ${second container}    invert=True

Get container log message
    [Arguments]    ${string pattern}    ${second container}=False    ${invert}=False
    [Documentation]    Get Docker logs for a current image and find a matching string based on input pattern, set second argument to True get logs of second container. If invert is True, asserts the pattern is NOT present.
    ${container name}=    Remove spaces from    ${TEST NAME}
    IF    ${second container} == True
         ${container name}=    Set Variable    ${container name}-2
    END
    Run Process    docker    logs    ${container name}    stdout=test_results/stdout-${container name}.txt    timeout=${DOCKER TIMEOUT}
    ${docker log}=    Get File    test_results/stdout-${container name}.txt
    IF    ${invert}
        Should Not Match    ${docker log}    ${string pattern}    msg=Found unexpected pattern '${string pattern}' in ${container name} container log
    ELSE
        Should Match    ${docker log}    ${string pattern}    msg=Did not find ${string pattern} in ${container name} container log
    END

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
    ${header}=    Create Dictionary    Content-type=application/x-www-form-urlencoded    Accept=multipart/mixed    boundary=BOUNDARY
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
    ${cluster_name}=    Get Local Cluster Name on port ${dockerport}
    ${response}=    POST On Session    RestSession    url=/manage/v2/clusters/${cluster_name}/dynamic-host-token    json=${token_body}    headers=${header}
    ${token_xml}=    Set Variable    ${response.text}
    ${token_content}=    Get Regexp Matches    ${token_xml}    <dynamic-host-token[^>]*>(.*)</dynamic-host-token>    1
    ${token}=    Set Variable    ${token_content[0]}
    RETURN    ${token}

Enable dynamic host feature on ${dockerport} for group ${group}
    [Documentation]    This enables the dynamic host feature for the specified group.
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Content-type=application/json    Accept=application/json
    # Create JSON payload to enable dynamic hosts
    ${json_body}=    Create Dictionary    group-name=${group}    allow-dynamic-hosts=${TRUE}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${dockerport}    headers=${headers}    auth=${auth}
    ${response}=    PUT On Session    RestSession    url=/manage/v2/groups/${group}/properties?format=json    json=${json_body}    headers=${header}
    RETURN    ${response}

Enable API token authentication on ${dockerport} for group ${group}
    [Documentation]    This enables the API token authentication for the specified group
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Content-type=application/json    Accept=application/json
    ${json_body}=    Create Dictionary    API-token-authentication=${TRUE}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${dockerport}    headers=${headers}    auth=${auth}
    ${response}=    PUT On Session    RestSession    url=/manage/v2/servers/Admin/properties?group-id=${group}    json=${json_body}    headers=${header}
    RETURN    ${response}

Disable dynamic host feature on ${dockerport} for group ${group}
    [Documentation]    This enables the dynamic host feature for the specified group.
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Content-type=application/json    Accept=application/json
    # Create JSON payload to enable dynamic hosts
    ${json_body}=    Create Dictionary    group-name=${group}    allow-dynamic-hosts=${FALSE}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${dockerport}    headers=${headers}    auth=${auth}
    ${response}=    PUT On Session    RestSession    url=/manage/v2/groups/${group}/properties?format=json    json=${json_body}    headers=${header}
    RETURN    ${response}

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
    Enable dynamic host feature on 7102 for group ${group}

Get Local Cluster Name on port ${port}
    [Documentation]    Gets the local cluster name from the MarkLogic Management API
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Accept=application/json
    ${response}=    Create Digest Session    ClusterNameSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    GET On Session    ClusterNameSession    url=/manage/v2/properties?format=json    headers=${header}
    ${cluster_name}=    Set Variable    ${response.json()["cluster-name"]}
    RETURN    ${cluster_name}

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
    RETURN    ${host_id}

Get All Dynamic Host IDs on port ${port} for group ${group}
    [Documentation]    Gets all dynamic host IDs from the MarkLogic cluster for a specific group
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Accept=application/json
    ${cluster_name}=    Get Local Cluster Name on port ${port}
    # Get all cluster-wide dynamic host IDs
    ${session}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    GET On Session    RestSession    url=/manage/v2/clusters/${cluster_name}/dynamic-hosts?format=json    headers=${header}
    ${has_hosts}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${response.json()}    dynamic-hosts
    @{all_dynamic_ids}=    Create List
    IF    ${has_hosts}
        @{all_dynamic_ids}=    Set Variable    ${response.json()["dynamic-hosts"]}
    END
    # Get all host IDs in the specified group
    ${resp2}=    GET On Session    RestSession    url=/manage/v2/hosts?format=json&group-id=${group}    headers=${header}
    ${group_items}=    Set Variable    ${resp2.json()["host-default-list"]["list-items"]}
    @{group_host_ids}=    Create List
    ${has_items}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${group_items}    list-item
    IF    ${has_items}
        ${items}=    Set Variable    ${group_items["list-item"]}
        ${is_list}=    Evaluate    isinstance($items, list)
        IF    ${is_list}
            FOR    ${item}    IN    @{items}
                Append To List    ${group_host_ids}    ${item["idref"]}
            END
        ELSE
            Append To List    ${group_host_ids}    ${items["idref"]}
        END
    END
    # Return intersection: dynamic hosts that are also in the specified group
    @{host_ids}=    Create List
    FOR    ${id}    IN    @{all_dynamic_ids}
        ${in_group}=    Evaluate    $id in $group_host_ids
        IF    ${in_group}
            Append To List    ${host_ids}    ${id}
        END
    END
    RETURN    ${host_ids}

Remove All Dynamic Hosts on port ${port} for group ${group}
    [Documentation]    Removes all dynamic hosts from the MarkLogic cluster for a specific group
    @{host_ids}=    Get All Dynamic Host IDs on port ${port} for group ${group}
    ${host_count}=    Get Length    ${host_ids}
    IF    ${host_count} > 0
        ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
        ${header}=    Create Dictionary    Content-type=application/xml
        ${host_elements}=    Evaluate    ''.join(f'<dynamic-host>{id}</dynamic-host>' for id in $host_ids)
        ${xml_body}=    Set Variable    <dynamic-hosts xmlns="http://marklogic.com/manage/dynamic-host">${host_elements}</dynamic-hosts>
        ${cluster_name}=    Get Local Cluster Name on port ${port}
        ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
        ${response}=    DELETE On Session    RestSession
        ...            url=/manage/v2/clusters/${cluster_name}/dynamic-hosts
        ...            data=${xml_body}    headers=${header}
        Log    Removed ${host_count} dynamic hosts from group ${group}
    ELSE
        Log    No dynamic hosts to remove from group ${group}
    END

Dynamic Host Join Successful on ${group} with ${port}
    ${token}=    Create dynamic host token for group ${group} on host bootstrap_3n and port 8001 using docker port 7102 with duration PT10M and comment no
    Init dynamic host ${port} with token ${token}

Dynamic Host Join Successful with d-node on ${group} with ${port}
    ${token}=    Create dynamic host token for group ${group} on host node2 and port 8001 using docker port 7202 with duration PT10M and comment no
    Init dynamic host ${port} with token ${token}
    Sleep    5s

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
    Restart compose from    compose-3core-11dynamic-hosts.yaml
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
    RETURN    ${host_ids}

Get Decoded Tokens on port ${port}
    [Documentation]    Gets all dynamic host tokens with decode=true to include decoded JWT fields (jti, group, exp)
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Accept=application/json
    ${cluster_name}=    Get Local Cluster Name on port ${port}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    GET On Session    RestSession    url=/manage/v2/clusters/${cluster_name}/dynamic-host-token?decode=true&format=json    headers=${header}
    RETURN    ${response}

Verify Decoded Tokens Contain Fields on port ${port}
    [Documentation]    Verifies that decoded tokens contain expected fields: jti, group, exp
    ${response}=    Get Decoded Tokens on port ${port}
    ${json}=    Set Variable    ${response.json()}
    
    # Check if response has the expected structure
    ${has_tokens_key}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${json}    dynamic-host-tokens
    IF    not ${has_tokens_key}
        Log    No dynamic-host-tokens in response. Available keys: ${json.keys()}
        Fail    Response does not contain dynamic-host-tokens. This might mean no tokens exist.
    END
    
    ${tokens}=    Set Variable    ${json["dynamic-host-tokens"]}
    ${is_list}=    Evaluate    isinstance($tokens, list)
    IF    not ${is_list}
        Fail    dynamic-host-tokens is not a list: ${tokens}
    END
    
    IF    len($tokens) == 0
        Fail    No tokens found in response - expected tokens to exist at this point in the test
    END
    
    FOR    ${token}    IN    @{tokens}
        # Each token should be a dict with 'payload' containing jti, group, exp
        ${payload}=    Set Variable    ${token["payload"]}
        Dictionary Should Contain Key    ${payload}    jti
        Dictionary Should Contain Key    ${payload}    group
        Dictionary Should Contain Key    ${payload}    exp
    END
    Log    All decoded tokens contain required fields (jti, group, exp)

Delete Token By JTI on port ${port} with jti ${jti}
    [Documentation]    Deletes a specific dynamic host token by its JTI value
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${cluster_name}=    Get Local Cluster Name on port ${port}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    DELETE On Session    RestSession    url=/manage/v2/clusters/${cluster_name}/dynamic-host-token/${jti}    expected_status=204

Delete Token By Invalid JTI on port ${port}
    [Documentation]    Verifies that deleting a token with an invalid JTI returns 404
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${cluster_name}=    Get Local Cluster Name on port ${port}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    DELETE On Session    RestSession    url=/manage/v2/clusters/${cluster_name}/dynamic-host-token/invalid-jti-does-not-exist    expected_status=404
    Log    Correctly received 404 for invalid JTI deletion

Delete Token By Host ID on port ${port} with host-id ${host_id}
    [Documentation]    Deletes all dynamic host tokens for a specific host-id using the /dynamic-hosts/{host-id} endpoint
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${cluster_name}=    Get Local Cluster Name on port ${port}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    DELETE On Session    RestSession    url=/manage/v2/clusters/${cluster_name}/dynamic-hosts/${host_id}    expected_status=204
    Log    Successfully deleted tokens for host-id: ${host_id}

Delete Token By Invalid Host ID on port ${port}
    [Documentation]    Verifies that deleting tokens with an invalid host-id returns 404
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${cluster_name}=    Get Local Cluster Name on port ${port}
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    DELETE On Session    RestSession    url=/manage/v2/clusters/${cluster_name}/dynamic-hosts/99999999999999999999    expected_status=404
    Log    Correctly received 404 for invalid host-id deletion

Verify Invalid Cluster Name Returns 404 on port ${port}
    [Documentation]    Verifies that using a nonexistent cluster name returns 404
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Accept=application/json
    ${response}=    Create Digest Session    RestSession    url=http://localhost:${port}    headers=${headers}    auth=${auth}
    ${response}=    GET On Session    RestSession    url=/manage/v2/clusters/nonexistent-cluster-name/dynamic-host-token?format=json    headers=${header}    expected_status=404
    Log    Correctly received 404 for nonexistent cluster name

Dynamic Host Join Fails When Token Expires ${group}
    [Documentation]    Tests that a token cannot be reused after it expires

    ${token}=    Create dynamic host token for group ${group} on host bootstrap_3n and port 8001 using docker port 7102 with duration PT5S and comment "short-lived token"
    Init dynamic host 8001 with token ${token}
    Sleep    10s    # Wait longer than the PT5S token duration
    ${status}=    Run Keyword And Return Status    Init dynamic host 8101 with token ${token}
    Should Be Equal    ${status}    ${FALSE}    Join succeeded with expired token when it should have failed
    Verify Dynamic Host Count on port 7102 for group ${group} equals 1

Dynamic Host Join Fails After Token Revoked ${group}
    [Documentation]    Tests that authentication fails after the token is revoked by the admin.

    ${token}=    Create dynamic host token for group ${group} on host bootstrap_3n and port 8001 using docker port 7102 with duration PT10M and comment "revoked token test"

    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Content-Type=application/xml
    ${xml_body}=    Set Variable    <dynamic-host-tokens><token>${token}</token></dynamic-host-tokens>
    ${cluster_name}=    Get Local Cluster Name on port 7102
    ${response}=    Create Digest Session    RestSession    url=http://localhost:7102    headers=${headers}    auth=${auth}
    ${response}=    DELETE On Session    RestSession    url=/manage/v2/clusters/${cluster_name}/dynamic-host-token    data=${xml_body}    headers=${header}

    ${status}=    Run Keyword And Return Status    Init dynamic host 8201 with token ${token}
    Should Be Equal    ${status}    ${FALSE}    Join succeeded with revoked token when it should have failed

Delete Token By JTI Succeeds on ${group}
    [Documentation]    Tests creating a token, extracting its JTI via decode=true, then deleting it by JTI

    ${token}=    Create dynamic host token for group ${group} on host bootstrap_3n and port 8001 using docker port 7102 with duration PT10M and comment "jti-delete-test"

    # Get the JTI of the token using decode=true
    ${decoded_response}=    Get Decoded Tokens on port 7102
    ${json}=    Set Variable    ${decoded_response.json()}
    
    # Check if response has tokens
    ${has_tokens_key}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${json}    dynamic-host-tokens
    IF    not ${has_tokens_key}
        Fail    No dynamic-host-tokens in decoded response. Response keys: ${json.keys()}
    END
    
    ${tokens}=    Set Variable    ${json["dynamic-host-tokens"]}
    ${is_list}=    Evaluate    isinstance($tokens, list)
    IF    not ${is_list}
        Fail    dynamic-host-tokens is not a list. Response: ${tokens}
    END
    
    IF    len($tokens) == 0
        Fail    No tokens found after creating token. Response: ${json}
    END
    
    # Get the last token (most recently created)
    ${last_token}=    Set Variable    ${tokens[-1]}
    ${payload}=    Set Variable    ${last_token["payload"]}
    ${jti}=    Set Variable    ${payload["jti"]}

    # Delete the token by JTI and verify
    Delete Token By JTI on port 7102 with jti ${jti}

    # Verify the join fails with the deleted token
    ${status}=    Run Keyword And Return Status    Init dynamic host 8201 with token ${token}
    Should Be Equal    ${status}    ${FALSE}    Join succeeded with JTI-deleted token when it should have failed

Delete Token By Host ID Succeeds on ${group}
    [Documentation]    Tests creating a token, initializing a dynamic host, then deleting token by host-id via query parameter

    ${token}=    Create dynamic host token for group ${group} on host bootstrap_3n and port 8001 using docker port 7102 with duration PT10M and comment "host-id-delete-test"

    # Initialize a dynamic host with the token
    Init dynamic host 8201 with token ${token}
    Sleep    5s    # Give the host time to fully initialize

    # Get the host-id of dynamic8 (the container behind port 8201) by its known stable hostname
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Accept=application/json
    ${response}=    Create Digest Session    RestSession    url=http://localhost:7102    headers=${headers}    auth=${auth}
    ${response}=    GET On Session    RestSession    url=/manage/v2/hosts?format=json&group-id=${group}    headers=${header}
    ${hosts}=    Set Variable    ${response.json()["host-default-list"]["list-items"]["list-item"]}

    # Normalise to a list (API returns a dict when only one host exists)
    ${is_list}=    Evaluate    isinstance($hosts, list)
    IF    not ${is_list}
        ${hosts}=    Create List    ${hosts}
    END

    # Find dynamic8 by its known hostname (stable identifier for the host on ports 8200-8210)
    ${host_id}=    Set Variable    ${EMPTY}
    FOR    ${h}    IN    @{hosts}
        ${is_dynamic8}=    Run Keyword And Return Status    Should Contain    ${h["nameref"]}    dynamic8
        IF    ${is_dynamic8}
            ${host_id}=    Set Variable    ${h["idref"]}
            BREAK
        END
    END

    Should Not Be Empty    ${host_id}    Could not find dynamic8 host-id in group ${group}
    Log    Found dynamic host-id for dynamic8

    # Delete the token by host-id
    Delete Token By Host ID on port 7102 with host-id ${host_id}

    # Verify deletion: dynamic8 must no longer appear in the group's host list
    ${response2}=    GET On Session    RestSession    url=/manage/v2/hosts?format=json&group-id=${group}    headers=${header}
    ${hosts_after}=    Set Variable    ${response2.json()["host-default-list"]["list-items"]["list-item"]}
    ${is_list2}=    Evaluate    isinstance($hosts_after, list)
    IF    not ${is_list2}
        ${hosts_after}=    Create List    ${hosts_after}
    END
    FOR    ${h}    IN    @{hosts_after}
        Should Not Contain    ${h["nameref"]}    dynamic8    DELETE by host-id did not remove dynamic8 from the group
    END
    Log    Token deletion by host-id verified: dynamic8 no longer in group ${group}

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

Ensure Test Results Directory Exists
    [Documentation]    Creates 'test_results' directory if needed.
    OperatingSystem.Create Directory    ${TEST_RESULTS_DIR}

Verify That marklogic.conf contains
    [Arguments]    @{variables}
    [Documentation]    Checks if a list of variables exists in /etc/marklogic.conf inside the container.
    ${container name}=    Remove spaces from    ${TEST_NAME}
    FOR    ${variable}    IN    @{variables}
        IF    'rootless' not in '${IMAGE_TYPE}'
            ${output}=    Run Process    docker    exec    ${container name}    sudo    grep    ${variable}    /etc/marklogic.conf
        ELSE
            ${output}=    Run Process    docker    exec    ${container name}    grep    ${variable}    /etc/marklogic.conf
        END
        Log    STDERR: ${output.stderr}
        Log    STDOUT: ${output.stdout}
        Should Not Be Empty    ${output.stdout}    Variable ${variable} not found in /etc/marklogic.conf        
    END

Couple Cluster on port ${local_port} with Foreign Cluster on port ${foreign_port}
    [Documentation]    Couples the local cluster with a foreign cluster by running admin:foreign-cluster-create
    ...    XQuery via /v1/eval. Uses admin library functions:
    ...    admin:cluster-get-id, admin:cluster-get-name, admin:foreign-host, admin:foreign-cluster-create,
    ...    admin:save-configuration-without-restart
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header_json}=    Create Dictionary    Accept=application/json

    # --- Gather foreign cluster info via Management API (port = management port 8002) ---
    ${foreign_mgmt}=    Create Digest Session    ForeignMgmt_${foreign_port}    url=http://localhost:${foreign_port}    headers=${headers}    auth=${auth}
    ${props}=    GET On Session    ForeignMgmt_${foreign_port}    url=/manage/v2/properties?format=json    headers=${header_json}
    ${foreign_cluster_id}=    Set Variable    ${props.json()["cluster-id"]}
    ${foreign_cluster_name}=    Set Variable    ${props.json()["cluster-name"]}

    # Get bootstrap host info - find host with 'bootstrap' in its hostname
    ${hosts_resp}=    GET On Session    ForeignMgmt_${foreign_port}    url=/manage/v2/hosts?format=json    headers=${header_json}
    ${hosts}=    Set Variable    ${hosts_resp.json()["host-default-list"]["list-items"]["list-item"]}
    # Default to first host, then override if we find one named 'bootstrap'
    ${foreign_host_id}=    Set Variable    ${hosts[0]["idref"]}
    ${foreign_host_name}=    Set Variable    ${hosts[0]["nameref"]}
    FOR    ${host}    IN    @{hosts}
        ${is_bootstrap}=    Run Keyword And Return Status    Should Contain    ${host["nameref"]}    bootstrap
        IF    ${is_bootstrap}
            ${foreign_host_id}=    Set Variable    ${host["idref"]}
            ${foreign_host_name}=    Set Variable    ${host["nameref"]}
            BREAK
        END
    END
    Log    Foreign cluster: id=${foreign_cluster_id} name=${foreign_cluster_name} bootstrap=${foreign_host_name} (id=${foreign_host_id})

    # --- Run XQuery on local cluster to register foreign cluster ---
    # /v1/eval is on port 8000; management API is on 8002; eval_port = local_port - 2
    ${eval_port}=    Evaluate    int(${local_port}) - 2
    # Build XQuery using admin:foreign-cluster-create - SSL disabled (fn:false()) so no cert exchange needed
    ${xquery}=    Catenate    SEPARATOR=\n
    ...    xquery version '1.0-ml';
    ...    import module namespace admin = 'http://marklogic.com/xdmp/admin' at '/MarkLogic/admin.xqy';
    ...    let $cfg := admin:get-configuration()
    ...    let $host := admin:foreign-host(xs:unsignedLong('${foreign_host_id}'), '${foreign_host_name}', xs:unsignedInt('7998'))
    ...    let $new-cfg := admin:foreign-cluster-create($cfg, xs:unsignedLong('${foreign_cluster_id}'), '${foreign_cluster_name}', xs:unsignedInt('10'), xs:unsignedInt('30'), (), fn:false(), (), (), (), $host)
    ...    return admin:save-configuration-without-restart($new-cfg)

    ${eval_session}=    Create Digest Session    LocalEval_${local_port}    url=http://localhost:${eval_port}    headers=${headers}    auth=${auth}
    ${data}=    Create Dictionary    xquery=${xquery}
    ${resp}=    POST On Session    LocalEval_${local_port}    url=/v1/eval    data=${data}    expected_status=200
    Log    Registered foreign cluster '${foreign_cluster_name}' on local cluster (port ${local_port})
    Sleep    2s    # Wait for configuration to propagate
    RETURN    ${foreign_cluster_name}

Verify Cross Cluster API Returns Error on port ${local_port} for cluster ${foreign_cluster_name}
    [Documentation]    Verifies behaviour when accessing a coupled (foreign) cluster's dynamic host token API.
    ...    Tested endpoints:
    ...    GET  /dynamic-host-token             → 200 empty list (cluster known/coupled, no cross-cluster token visibility)
    ...    POST /dynamic-host-token             → 400 Bad Request (cannot create tokens for foreign cluster)
    ...    DELETE /dynamic-host-token/{jti}     → 404 Not Found (real JTI exists on foreign cluster but not visible cross-cluster)
    ...    DELETE /dynamic-hosts/{real-host-id} → 404 Not Found (dynamic hosts not visible cross-cluster)
    ${auth}    ${headers}=    Generate digest authorization for    ${DEFAULT ADMIN USER}    ${DEFAULT ADMIN PASS}
    ${header}=    Create Dictionary    Accept=application/json
    ${header_post}=    Create Dictionary    Content-type=application/json    Accept=application/json
    ${response}=    Create Digest Session    CrossClusterSess_${local_port}    url=http://localhost:${local_port}    headers=${headers}    auth=${auth}

    # Derive foreign management port: cluster2 = 7302, cluster1 = 7102
    ${is_cluster2}=    Run Keyword And Return Status    Should Contain    ${foreign_cluster_name}    cluster2
    ${foreign_mgmt_port}=    Set Variable If    ${is_cluster2}    7302    7102
    ${foreign_session}=    Create Digest Session    ForeignSess_${foreign_mgmt_port}    url=http://localhost:${foreign_mgmt_port}    headers=${headers}    auth=${auth}

    # --- /dynamic-host-token endpoint ---

    # GET dynamic host tokens using foreign cluster name - returns 200 with empty list (cluster is known/coupled)
    # This distinguishes from 404 (XDMP-NOSUCHCLUSTER) which would mean the clusters aren't coupled
    ${response}=    GET On Session    CrossClusterSess_${local_port}    url=/manage/v2/clusters/${foreign_cluster_name}/dynamic-host-token?format=json    headers=${header}    expected_status=200
    ${tokens}=    Set Variable    ${response.json().get("dynamic-host-tokens", [])}
    Should Be Empty    ${tokens}    Expected no tokens visible on foreign cluster, got: ${tokens}
    Log    Correctly received 200 with empty tokens - cluster is coupled/known

    # POST (create) token for foreign cluster - should return 400 (Bad Request)
    # Use the local cluster's own bootstrap host and container Admin port so the 400 is caused by
    # the cross-cluster restriction, not an invalid/unreachable host-mapped port combination.
    # is_cluster2=True means foreign=cluster2 → local=cluster1 → cluster1_bootstrap; else local=cluster2 → cluster2_bootstrap
    ${local_bootstrap_name}=    Set Variable If    ${is_cluster2}    cluster1_bootstrap    cluster2_bootstrap
    ${token_details}=    Create Dictionary    group=Default    host=${local_bootstrap_name}    port=8001    duration=PT10M    comment=test
    ${token_body}=    Create Dictionary    dynamic-host-token=${token_details}
    ${response}=    POST On Session    CrossClusterSess_${local_port}    url=/manage/v2/clusters/${foreign_cluster_name}/dynamic-host-token    json=${token_body}    headers=${header_post}    expected_status=400
    Log    Correctly received 400 when POST-ing token on foreign cluster

    # Create a real token on the foreign cluster (via its own API) and extract its JTI
    ${foreign_cluster_name_local}=    Get Local Cluster Name on port ${foreign_mgmt_port}
    ${foreign_bootstrap_name}=    Set Variable If    ${is_cluster2}    cluster2_bootstrap    cluster1_bootstrap
    ${token_details_foreign}=    Create Dictionary    group=Default    host=${foreign_bootstrap_name}    port=8001    duration=PT10M    comment=cross-cluster-jti-test
    ${token_body_foreign}=    Create Dictionary    dynamic-host-token=${token_details_foreign}
    ${create_resp}=    POST On Session    ForeignSess_${foreign_mgmt_port}    url=/manage/v2/clusters/${foreign_cluster_name_local}/dynamic-host-token    json=${token_body_foreign}    headers=${header_post}    expected_status=201
    # Decode to get the JTI of the newly created token
    ${decoded}=    GET On Session    ForeignSess_${foreign_mgmt_port}    url=/manage/v2/clusters/${foreign_cluster_name_local}/dynamic-host-token?decode=true&format=json    headers=${header}
    ${foreign_tokens}=    Set Variable    ${decoded.json()["dynamic-host-tokens"]}
    ${real_jti}=    Set Variable    ${foreign_tokens[-1]["payload"]["jti"]}
    # DELETE that real JTI cross-cluster from the local cluster - returns 404 (tokens not visible cross-cluster)
    ${response}=    DELETE On Session    CrossClusterSess_${local_port}    url=/manage/v2/clusters/${foreign_cluster_name}/dynamic-host-token/${real_jti}    expected_status=404
    Log    Correctly received 404 when DELETE-ing real foreign JTI cross-cluster
    # Cleanup: delete the token on the foreign cluster directly
    ${response}=    DELETE On Session    ForeignSess_${foreign_mgmt_port}    url=/manage/v2/clusters/${foreign_cluster_name_local}/dynamic-host-token/${real_jti}    expected_status=204

    # --- /dynamic-hosts endpoint ---

    # Get a real host-id from the foreign cluster's own Management API
    ${fhosts_resp}=    GET On Session    ForeignSess_${foreign_mgmt_port}    url=/manage/v2/hosts?format=json    headers=${header}
    ${fhosts}=    Set Variable    ${fhosts_resp.json()["host-default-list"]["list-items"]["list-item"]}
    ${is_list}=    Evaluate    isinstance($fhosts, list)
    ${real_host_id}=    Set Variable If    ${is_list}    ${fhosts[0]["idref"]}    ${fhosts["idref"]}
    Log    Real foreign host-id to test: ${real_host_id}
    # DELETE /dynamic-hosts/{real-host-id} cross-cluster - returns 404 (dynamic hosts not visible cross-cluster)
    ${response}=    DELETE On Session    CrossClusterSess_${local_port}    url=/manage/v2/clusters/${foreign_cluster_name}/dynamic-hosts/${real_host_id}    expected_status=404
    Log    Correctly received 404 when DELETE-ing real foreign host-id cross-cluster
