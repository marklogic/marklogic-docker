# Copyright © 2018-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
*** Settings ***
Resource         keywords.resource
Documentation    Test all initialization options using Docker run and Docker Compose.
...              Each test case creates and then tears down one or more Docker containers.
...              Verification is done using REST calls to MarkLogic server and Docker logs.
Suite Setup      Ensure Test Results Directory Exists

*** Test Cases ***

Smoke Test
    Create container with
    Docker log should contain    *MARKLOGIC_INIT is set to false or not defined, not initializing.*
    [Teardown]    Delete container

Uninitialized MarkLogic container
    Create container with    -e    MARKLOGIC_INIT=false
    IF    'rootless' not in '${IMAGE_TYPE}' # ROOT image
        Docker log should contain    *OVERWRITE_ML_CONF is true, deleting existing /etc/marklogic.conf and overwriting with ENV variables.*
    END
    IF    'rootless' in '${IMAGE_TYPE}' # ROOTLESS image
        Docker log should contain    */etc/marklogic.conf will be appended with provided environment variables.*
    END
    Docker log should contain    *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
    Docker log should contain    *MARKLOGIC_INIT is set to false or not defined, not initializing.*
    Docker log should contain    *Starting container with MarkLogic Server.*
    Docker log should contain    *| server ver: ${MARKLOGIC_VERSION} | scripts ver: ${MARKLOGIC_DOCKER_VERSION} | image type: ${IMAGE_TYPE} | branch: ${BUILD_BRANCH} |*
    Docker log should contain    *Appended MARKLOGIC_PID_FILE to /etc/marklogic.conf*
    Docker log should contain    *Appended MARKLOGIC_UMASK to /etc/marklogic.conf*
    Docker log should contain    *Appended MARKLOGIC_USER to /etc/marklogic.conf*
    Docker log should contain    *Appended MARKLOGIC_EC2_HOST to /etc/marklogic.conf*
    Verify response for unauthenticated request with    8000    *Forbidden*
    Verify response for unauthenticated request with    8001    *This server must now self-install the initial databases and application servers. Click OK to continue.*
    Verify response for unauthenticated request with    8002    *Forbidden*
    Verify response for authenticated request with    8000    *Forbidden*
    Verify response for authenticated request with    8001    *This server must now self-install the initial databases and application servers. Click OK to continue.*
    Verify response for authenticated request with    8002    *Forbidden*
    [Teardown]    Delete container

Uninitialized MarkLogic container with no parameters
    Create container with
    IF    'rootless' not in '${IMAGE_TYPE}' # ROOT image
        Docker log should contain    *OVERWRITE_ML_CONF is true, deleting existing /etc/marklogic.conf and overwriting with ENV variables.*
    END
    IF    'rootless' in '${IMAGE_TYPE}' # ROOTLESS image
        Docker log should contain    */etc/marklogic.conf will be appended with provided environment variables.*
    END
    Docker log should contain    *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
    Docker log should contain    *MARKLOGIC_INIT is set to false or not defined, not initializing.*
    Docker log should contain    *Starting container with MarkLogic Server.*
    Docker log should contain    *| server ver: ${MARKLOGIC_VERSION} | scripts ver: ${MARKLOGIC_DOCKER_VERSION} | image type: ${IMAGE_TYPE} | branch: ${BUILD_BRANCH} |*
    Docker log should contain    *Appended MARKLOGIC_PID_FILE to /etc/marklogic.conf*
    Docker log should contain    *Appended MARKLOGIC_UMASK to /etc/marklogic.conf*
    Docker log should contain    *Appended MARKLOGIC_USER to /etc/marklogic.conf*
    Docker log should contain    *Appended MARKLOGIC_EC2_HOST to /etc/marklogic.conf*
    Verify That marklogic.conf contains    MARKLOGIC_PID_FILE    MARKLOGIC_UMASK    MARKLOGIC_USER    MARKLOGIC_EC2_HOST=0
    Verify response for unauthenticated request with    8000    *Forbidden*
    Verify response for unauthenticated request with    8001    *This server must now self-install the initial databases and application servers. Click OK to continue.*
    Verify response for unauthenticated request with    8002    *Forbidden*
    Verify response for authenticated request with    8000    *Forbidden*
    Verify response for authenticated request with    8001    *This server must now self-install the initial databases and application servers. Click OK to continue.*
    Verify response for authenticated request with    8002    *Forbidden*
    [Teardown]    Delete container

Initialized MarkLogic container
    Create container with    -e    MARKLOGIC_INIT=true
    ...                      -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                      -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    IF    'rootless' not in '${IMAGE_TYPE}' # ROOT image
        Docker log should contain    *OVERWRITE_ML_CONF is true, deleting existing /etc/marklogic.conf and overwriting with ENV variables.*
    END
    IF    'rootless' in '${IMAGE_TYPE}' # ROOTLESS image
        Docker log should contain    */etc/marklogic.conf will be appended with provided environment variables.*
    END
    Docker log should contain    *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
    Docker log should contain    *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Docker log should contain    *Starting container with MarkLogic Server.*
    Docker log should contain    *| server ver: ${MARKLOGIC_VERSION} | scripts ver: ${MARKLOGIC_DOCKER_VERSION} | image type: ${IMAGE_TYPE} | branch: ${BUILD_BRANCH} |*
    Docker log should contain    *Appended MARKLOGIC_PID_FILE to /etc/marklogic.conf*
    Docker log should contain    *Appended MARKLOGIC_UMASK to /etc/marklogic.conf*
    Docker log should contain    *Appended MARKLOGIC_USER to /etc/marklogic.conf*
    Docker log should contain    *Appended MARKLOGIC_EC2_HOST to /etc/marklogic.conf*
    Verify That marklogic.conf contains    MARKLOGIC_PID_FILE    MARKLOGIC_UMASK    MARKLOGIC_USER    MARKLOGIC_EC2_HOST=0
    Verify response for unauthenticated request with    8000    *Unauthorized*
    Verify response for unauthenticated request with    8001    *Unauthorized*
    Verify response for unauthenticated request with    8002    *Unauthorized*
    Verify response for authenticated request with    8000    *Query Console*
    Verify response for authenticated request with    8001    *No license key has been entered*
    Verify response for authenticated request with    8002    *Monitoring Dashboard*
    [Teardown]    Delete container

Initialized MarkLogic container with latency
    [Tags]    long_running
    [Documentation]    This test verifies the initialization of the MarkLogic container with high latency.
    ...                Setup on a linux host can be done with the following commands:
    ...                sudo dnf install  kernel-modules-extra
    ...                sudo modprobe sch_netem
    Skip If    '${IMAGE_TYPE}' != 'ubi'
    Create container with latency    -e    MARKLOGIC_INIT=true
    ...                      -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                      -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    IF    'rootless' not in '${IMAGE_TYPE}' # ROOT image
        Docker log should contain    *OVERWRITE_ML_CONF is true, deleting existing /etc/marklogic.conf and overwriting with ENV variables.*
    END
    IF    'rootless' in '${IMAGE_TYPE}' # ROOTLESS image
        Docker log should contain    */etc/marklogic.conf will be appended with provided environment variables.*
    END
    Docker log should contain    *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
    Docker log should contain    *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Docker log should contain    *Starting container with MarkLogic Server.*
    Docker log should contain    *| server ver: ${MARKLOGIC_VERSION} | scripts ver: ${MARKLOGIC_DOCKER_VERSION} | image type: ${IMAGE_TYPE} | branch: ${BUILD_BRANCH} |*
    Docker log should contain    *Appended MARKLOGIC_PID_FILE to /etc/marklogic.conf*
    Docker log should contain    *Appended MARKLOGIC_UMASK to /etc/marklogic.conf*
    Docker log should contain    *Appended MARKLOGIC_USER to /etc/marklogic.conf*
    Docker log should contain    *Appended MARKLOGIC_EC2_HOST to /etc/marklogic.conf*
    Verify That marklogic.conf contains    MARKLOGIC_PID_FILE    MARKLOGIC_UMASK    MARKLOGIC_USER    MARKLOGIC_EC2_HOST=0
    Verify response for unauthenticated request with    8000    *Unauthorized*
    Verify response for unauthenticated request with    8001    *Unauthorized*
    Verify response for unauthenticated request with    8002    *Unauthorized*
    Verify response for authenticated request with    8000    *Query Console*
    Verify response for authenticated request with    8001    *No license key has been entered*
    Verify response for authenticated request with    8002    *Monitoring Dashboard*
    [Teardown]    Delete container

Upgrade MarkLogic container
    Skip If  'rootless' in '${IMAGE_TYPE}'  msg = Skipping Upgrade MarkLogic test for rootless image
    Create test container with    -e    MARKLOGIC_INIT=true
...                               -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
...                               -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    Docker log should contain    *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
    Docker log should contain    *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Docker log should contain    *Starting container with MarkLogic Server.*
    Docker log should contain    *| server ver: ${MARKLOGIC_VERSION} | scripts ver: ${MARKLOGIC_DOCKER_VERSION} | image type: ${IMAGE_TYPE} | branch: ${BUILD_BRANCH} |*
    Verify response for unauthenticated request with    8000    *Unauthorized*
    Verify response for unauthenticated request with    8001    *Unauthorized*
    Verify response for unauthenticated request with    8002    *Unauthorized*
    Verify response for authenticated request with    8000    *Query Console*
    Verify response for authenticated request with    8001    *No license key has been entered*
    Verify response for authenticated request with    8002    *Monitoring Dashboard*
    Stop container
    Create upgrade container with    
    Docker log should contain    *MARKLOGIC_INIT is true, but the server is already initialized. Skipping initialization.*    True
    Verify response for authenticated request with    8000    *Query Console*
    Verify response for authenticated request with    8001    *No license key has been entered*
    Verify response for authenticated request with    8002    *Monitoring Dashboard*
    [Teardown]    Run Keywords    Delete container    True
    ...           AND             Delete Volume

Upgrade MarkLogic container with init parameter
    Skip If  'rootless' in '${IMAGE_TYPE}'  msg = Skipping Upgrade MarkLogic test for rootless image
    Create test container with    -e    MARKLOGIC_INIT=true
...                               -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
...                               -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    Docker log should contain    *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
    Docker log should contain    *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Docker log should contain    *Starting container with MarkLogic Server.*
    Docker log should contain    *| server ver: ${MARKLOGIC_VERSION} | scripts ver: ${MARKLOGIC_DOCKER_VERSION} | image type: ${IMAGE_TYPE} | branch: ${BUILD_BRANCH} |*
    Verify response for unauthenticated request with    8000    *Unauthorized*
    Verify response for unauthenticated request with    8001    *Unauthorized*
    Verify response for unauthenticated request with    8002    *Unauthorized*
    Verify response for authenticated request with    8000    *Query Console*
    Verify response for authenticated request with    8001    *No license key has been entered*
    Verify response for authenticated request with    8002    *Monitoring Dashboard*
    Stop container
    Create upgrade container with    -e    MARKLOGIC_INIT=true
    Docker log should contain    *Cluster config complete, marking this container as ready.*    True
    Verify response for authenticated request with    8000    *Query Console*
    Verify response for authenticated request with    8001    *No license key has been entered*
    Verify response for authenticated request with    8002    *Monitoring Dashboard*
    [Teardown]    Run Keywords    Delete container    True
    ...           AND             Delete Volume

Upgrade MarkLogic container with init and credential parameters
    Skip If  'rootless' in '${IMAGE_TYPE}'  msg = Skipping Upgrade MarkLogic test for rootless image
    Create test container with    -e    MARKLOGIC_INIT=true
...                               -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
...                               -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    Docker log should contain    *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
    Docker log should contain    *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Docker log should contain    *Starting container with MarkLogic Server.*
    Docker log should contain    *| server ver: ${MARKLOGIC_VERSION} | scripts ver: ${MARKLOGIC_DOCKER_VERSION} | image type: ${IMAGE_TYPE} | branch: ${BUILD_BRANCH} |*
    Verify response for unauthenticated request with    8000    *Unauthorized*
    Verify response for unauthenticated request with    8001    *Unauthorized*
    Verify response for unauthenticated request with    8002    *Unauthorized*
    Verify response for authenticated request with    8000    *Query Console*
    Verify response for authenticated request with    8001    *No license key has been entered*
    Verify response for authenticated request with    8002    *Monitoring Dashboard*
    Stop container
    Create upgrade container with    -e    MARKLOGIC_INIT=true
    ...                               -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                               -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    Docker log should contain    *Cluster config complete, marking this container as ready.*    True
    Verify response for authenticated request with    8000    *Query Console*
    Verify response for authenticated request with    8001    *No license key has been entered*
    Verify response for authenticated request with    8002    *Monitoring Dashboard*
    [Teardown]    Run Keywords    Delete container    True
    ...           AND             Delete Volume

Initialized MarkLogic container with admin password containing special characters
    Create container with    -e    MARKLOGIC_INIT=true
...                          -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
...                          -e    MARKLOGIC_ADMIN_PASSWORD=${SPEC CHARS ADMIN PASS}
    Docker log should contain    *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
    Docker log should contain    *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Docker log should contain    *| server ver: ${MARKLOGIC_VERSION} | scripts ver: ${MARKLOGIC_DOCKER_VERSION} | image type: ${IMAGE_TYPE} | branch: ${BUILD_BRANCH} |*
    Verify response for unauthenticated request with    8000    *Unauthorized*
    Verify response for unauthenticated request with    8001    *Unauthorized*
    Verify response for unauthenticated request with    8002    *Unauthorized*
    Verify response for authenticated request with    8000    *Query Console*    ${SPEC CHARS ADMIN PASS}
    Verify response for authenticated request with    8001    *No license key has been entered*    ${SPEC CHARS ADMIN PASS}
    Verify response for authenticated request with    8002    *Monitoring Dashboard*    ${SPEC CHARS ADMIN PASS}
    [Teardown]    Delete container

Initialized MarkLogic container with license key installed and MARKLOGIC_INIT set to TRUE
    Create container with    -e    MARKLOGIC_INIT=TRUE
    ...                      -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                      -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    ...                      -e    LICENSEE=${LICENSEE}
    ...                      -e    LICENSE_KEY=${LICENSE KEY}
    Docker log should contain    *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
    Docker log should contain    *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Verify response for unauthenticated request with    8000    *Unauthorized*
    Verify response for unauthenticated request with    8001    *Unauthorized*
    Verify response for unauthenticated request with    8002    *Unauthorized*
    Verify response for authenticated request with    8000    *Query Console*
    Verify response for authenticated request with    8001/license.xqy    *MarkLogic - Version 9 QA Test License*
    Verify response for authenticated request with    8002    *Monitoring Dashboard*
    [Teardown]    Delete container

Initialized MarkLogic container without credentials
    [Tags]    negative
    Create failing container with    -e    MARKLOGIC_INIT=true
    Docker log should contain    *MARKLOGIC_ADMIN_USERNAME and MARKLOGIC_ADMIN_PASSWORD must be set.*
    [Teardown]    Delete container

Initialized MarkLogic container with invalid value for MARKLOGIC_JOIN_CLUSTER
    [Tags]    negative
    Create failing container with    -e    MARKLOGIC_INIT=true
    ...                              -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                              -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    ...                              -e    MARKLOGIC_JOIN_CLUSTER=invalid
    Docker log should contain    *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Docker log should contain    *Error: MARKLOGIC_JOIN_CLUSTER must be true or false.*
    [Teardown]    Delete container

Invalid value for INIT
    [Tags]    negative
    Create failing container with    -e    MARKLOGIC_INIT=invalid
    ...                              -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                              -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    Docker log should contain    *Error: MARKLOGIC_INIT must be true or false.*
    [Teardown]    Delete container

Invalid value for HOSTNAME
    [Tags]    negative
    Create failing container with    -e    HOSTNAME=invalid_hostname
    ...                              -e    MARKLOGIC_INIT=true
    ...                              -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                              -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    Docker log should contain    *Error: Failed to restart invalid_hostname*
    [Teardown]    Delete container

Initialized MarkLogic container without config overrides
    Create container with    -e    MARKLOGIC_INIT=true
    ...                      -e    OVERWRITE_ML_CONF=false
    ...                      -e    TZ=America/Los_Angeles
    ...                      -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                      -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    # ROOT image
    IF    'rootless' not in '${IMAGE_TYPE}'
        Docker log should contain    *OVERWRITE_ML_CONF is false, not writing to /etc/marklogic.conf*
        Docker log should contain    *TZ is defined, setting timezone to America/Los_Angeles.*
        Docker log should NOT contain    *Appended MARKLOGIC_PID_FILE to /etc/marklogic.conf*
        Docker log should NOT contain    *Appended MARKLOGIC_UMASK to /etc/marklogic.conf*
        Docker log should NOT contain    *Appended MARKLOGIC_USER to /etc/marklogic.conf*
        Docker log should NOT contain    *Appended MARKLOGIC_EC2_HOST to /etc/marklogic.conf*
    END
    # ROOTLESS image doesn't support OVERWRITE_ML_CONF=false
    IF    'rootless' in '${IMAGE_TYPE}'
        Docker log should contain    */etc/marklogic.conf will be appended with provided environment variables.*
        Docker log should contain    *Appended MARKLOGIC_PID_FILE to /etc/marklogic.conf*
        Docker log should contain    *Appended MARKLOGIC_UMASK to /etc/marklogic.conf*
        Docker log should contain    *Appended MARKLOGIC_USER to /etc/marklogic.conf*
        Docker log should contain    *Appended MARKLOGIC_EC2_HOST to /etc/marklogic.conf*
        Verify That marklogic.conf contains    MARKLOGIC_PID_FILE    MARKLOGIC_UMASK    MARKLOGIC_USER    MARKLOGIC_EC2_HOST=0    TZ=America/Los_Angeles
    END
    Docker log should contain    *INSTALL_CONVERTERS is false, not installing converters.*
    Docker log should contain    *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Verify response for unauthenticated request with    8000    *Unauthorized*
    Verify response for unauthenticated request with    8001    *Unauthorized*
    Verify response for unauthenticated request with    8002    *Unauthorized*
    Verify response for authenticated request with    8000    *Query Console*
    Verify response for authenticated request with    8001    *No license key has been entered*
    Verify response for authenticated request with    8002    *Monitoring Dashboard*
    Verify container timezone    America/Los_Angeles
    [Teardown]    Delete container

Initialized MarkLogic container with config overrides
    Create container with    -e    MARKLOGIC_INIT=true
    ...                      -e    OVERWRITE_ML_CONF=true
    ...                      -e    TZ=America/Los_Angeles
    ...                      -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                      -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    IF    'rootless' not in '${IMAGE_TYPE}' # ROOT image
        Docker log should contain    *OVERWRITE_ML_CONF is true, deleting existing /etc/marklogic.conf and overwriting with ENV variables.*
        Docker log should contain    *TZ is defined, setting timezone to America/Los_Angeles.*
    END
    IF    'rootless' in '${IMAGE_TYPE}' # ROOTLESS image
        Docker log should contain    */etc/marklogic.conf will be appended with provided environment variables.*
    END
    Verify That marklogic.conf contains    TZ=America/Los_Angeles
    Docker log should contain    *INSTALL_CONVERTERS is false, not installing converters.*
    Docker log should contain    *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Verify response for unauthenticated request with    8000    *Unauthorized*
    Verify response for unauthenticated request with    8001    *Unauthorized*
    Verify response for unauthenticated request with    8002    *Unauthorized*
    Verify response for authenticated request with    8000    *Query Console*
    Verify response for authenticated request with    8001    *No license key has been entered*
    Verify response for authenticated request with    8002    *Monitoring Dashboard*
    Verify container timezone    America/Los_Angeles
    [Teardown]    Delete container

Single node compose example
    [Tags]    compose
    ${compose test file}=    Set Variable    ../docker-compose/marklogic-single-node.yaml
    Start compose from    ${compose test file}
    Verify response for unauthenticated request with    8000    *Unauthorized*
    Verify response for unauthenticated request with    8001    *Unauthorized*
    Verify response for unauthenticated request with    8002    *Unauthorized*
    Verify response for authenticated request with    8000    *Query Console*
    Verify response for authenticated request with    8001    *No license key has been entered*
    Verify response for authenticated request with    8002    *Monitoring Dashboard*
    Host count on port 8002 should be 1
    IF    'rootless' not in '${IMAGE_TYPE}'
        Compose logs should contain    ${compose test file}    *TZ is defined, setting timezone to Europe/Prague.*
    END
    Verify container timezone    Europe/Prague
    [Teardown]    Delete compose from    ../docker-compose/marklogic-single-node.yaml

Single node compose example with special characters in secrets file
    [Tags]    compose
    Start compose from    ../docker-compose/marklogic-single-node.yaml    ${SPEC CHARS ADMIN PASS}
    Verify response for unauthenticated request with    8000    *Unauthorized*
    Verify response for unauthenticated request with    8001    *Unauthorized*
    Verify response for unauthenticated request with    8002    *Unauthorized*
    Verify response for authenticated request with    8000    *Query Console*    ${SPEC CHARS ADMIN PASS}
    Verify response for authenticated request with    8001    *No license key has been entered*    ${SPEC CHARS ADMIN PASS}
    Verify response for authenticated request with    8002    *Monitoring Dashboard*    ${SPEC CHARS ADMIN PASS}
    [Teardown]    Delete compose from    ../docker-compose/marklogic-single-node.yaml

Single node compose with special characters in yaml
    [Tags]    compose
    Start compose from    ../test/compose-test-1.yaml    ${SPEC CHARS ADMIN PASS}
    Verify response for unauthenticated request with    7100    *Unauthorized*
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7102    *Unauthorized*
    Verify response for authenticated request with    7100    *Query Console*    ${SPEC CHARS ADMIN PASS}
    Verify response for authenticated request with    7101    *No license key has been entered*    ${SPEC CHARS ADMIN PASS}
    Verify response for authenticated request with    7102    *Monitoring Dashboard*    ${SPEC CHARS ADMIN PASS}
    [Teardown]    Delete compose from    ../test/compose-test-1.yaml

Three node compose example
    [Tags]    compose
    Start compose from    ../docker-compose/marklogic-multi-node.yaml
    Verify response for unauthenticated request with    7100    *Unauthorized*
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7102    *Unauthorized*
    Verify response for unauthenticated request with    7200    *Unauthorized*
    Verify response for unauthenticated request with    7201    *Unauthorized*
    Verify response for unauthenticated request with    7202    *Unauthorized*
    Verify response for unauthenticated request with    7300    *Unauthorized*
    Verify response for unauthenticated request with    7301    *Unauthorized*
    Verify response for unauthenticated request with    7302    *Unauthorized*
    Verify response for authenticated request with    7100    *Query Console*
    Verify response for authenticated request with    7101    *No license key has been entered*
    Verify response for authenticated request with    7102    *Monitoring Dashboard*
    Verify response for authenticated request with    7200    *Query Console*
    Verify response for authenticated request with    7201    *No license key has been entered*
    Verify response for authenticated request with    7202    *Monitoring Dashboard*
    Verify response for authenticated request with    7300    *Query Console*
    Verify response for authenticated request with    7301    *No license key has been entered*
    Verify response for authenticated request with    7302    *Monitoring Dashboard*
    Host count on port 7102 should be 3
    Host count on port 7202 should be 3
    Host count on port 7302 should be 3
    [Teardown]    Delete compose from    ../docker-compose/marklogic-multi-node.yaml

Two node compose example with node joining enode group
    [Tags]    compose
    Start compose from    ./compose-test-6.yaml
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7102    *Unauthorized*
    Verify response for authenticated request with    7100    *Query Console*
    Verify response for authenticated request with    7101    *No license key has been entered*
    Verify response for authenticated request with    7102    *Monitoring Dashboard*
    Add group enode on host on port 7102
    Start compose from    ./compose-test-7.yaml    readiness=False
    Compose logs should contain    ./compose-test-7.yaml    *Cluster config complete, marking this container as ready.*
    Host node2 should be part of group enode
    [Teardown]    Run keywords    
    ...    Delete compose from    ./compose-test-6.yaml
    ...    AND    Delete compose from    ./compose-test-7.yaml

# Tests for invalid certificate/CA, invalid    value for MARKLOGIC_JOIN_TLS_ENABLED 
Compose example with node joining cluster using https with invalid parameter values
    [Tags]    compose    negative
    Create invalid certificate file
    Start compose from    ./compose-test-10.yaml    readiness=False
    Compose logs should contain    ./compose-test-10.yaml    *MARKLOGIC_JOIN_TLS_ENABLED must be set to true or false, please review the configuration. Container shutting down.*
    [Teardown]    Delete compose from    ./compose-test-10.yaml

Compose example with node joining cluster using https and missing certificate parameter
    [Tags]    compose    negative
    Start compose from    ./compose-test-11.yaml    readiness=False
    Compose logs should contain    ./compose-test-11.yaml    *MARKLOGIC_JOIN_CACERT_FILE is not set, please review the configuration. Container shutting down.*
    [Teardown]    Delete compose from    ./compose-test-11.yaml

Two node compose example with bootstrap node without SSL enabled and node joining cluster using https
    [Tags]    compose    negative
    Start compose from    ./compose-test-12.yaml
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7102    *Unauthorized*
    Verify response for authenticated request with    7100    *Query Console*
    Verify response for authenticated request with    7101    *No license key has been entered*
    Verify response for authenticated request with    7102    *Monitoring Dashboard*
    Create invalid certificate file
    Start compose from    ./compose-test-13.yaml    readiness=False
    Compose logs should contain    ./compose-test-13.yaml    *TLS is not enabled on bootstrap_host_name host, please verify the configuration. Container shutting down.*
    [Teardown]    Run keywords    
    ...    Delete compose from    ./compose-test-12.yaml
    ...    AND    Delete compose from    ./compose-test-13.yaml

Two node compose example with node joining cluster using invalid CAcertificate
    [Tags]    compose    negative
    Start compose from    ./compose-test-14.yaml
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for authenticated request with    7101    *No license key has been entered*
    Add certificate template on bootstrap host    ./test_template.json    7102
    Get CAcertificate for testTemplate 7100
    Apply certificate testTemplate on App Server Admin 7102
    Apply certificate testTemplate on App Server Manage 7102
    Create invalid certificate file
    Start compose from    ./compose-test-15.yaml    readiness=False
    Compose logs should contain    ./compose-test-15.yaml    *MARKLOGIC_JOIN_CACERT_FILE is not valid, please check above error for details. Node shutting down.*
    [Teardown]    Run keywords    
    ...    Delete compose from    ./compose-test-14.yaml
    ...    AND    Delete compose from    ./compose-test-15.yaml

Two node compose example with node joining cluster using https
    [Tags]    compose
    Start compose from    ./compose-test-1.yaml
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for authenticated request with    7101    *No license key has been entered*
    Add certificate template on bootstrap host    ./test_template.json    7102
    Get CAcertificate for testTemplate 7100
    Apply certificate testTemplate on App Server Admin 7102
    Apply certificate testTemplate on App Server Manage 7102
    Start compose from    ./compose-test-2.yaml    readiness=False
    Compose logs should contain    ./compose-test-2.yaml    *Cluster config complete, marking this container as ready.*
    [Teardown]    Run keywords    
    ...    Delete compose from    ./compose-test-1.yaml
    ...    AND    Delete compose from    ./compose-test-2.yaml

Single node compose example with bootstrap node joining trying to itself
    [Tags]    compose    negative
    ${compose test file}=    Set Variable    ./compose-test-8.yaml
    Start compose from    ${compose test file}
    Verify response for unauthenticated request with    7100    *Unauthorized*
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7102    *Unauthorized*
    Verify response for authenticated request with    7100    *Query Console*
    Verify response for authenticated request with    7101    *No license key has been entered*
    Verify response for authenticated request with    7102    *Monitoring Dashboard*
    IF    'rootless' not in '${IMAGE_TYPE}'
        Compose logs should contain    ${compose test file}    *bootstrap*TZ is defined, setting timezone to America/Los_Angeles.*
    END
    Compose logs should contain    ${compose test file}    *bootstrap*MARKLOGIC_ADMIN_PASSWORD is set, using ENV for admin password.*
    Compose logs should contain    ${compose test file}    *bootstrap*MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Compose logs should contain    ${compose test file}    *bootstrap*HOST cannot join itself, skipped joining cluster.*
    Host count on port 7102 should be 1
    Verify container timezone    America/Los_Angeles    port=7100
    [Teardown]    Delete compose from    ${compose test file}
    
Two node compose example with incorrect bootstrap host name
    [Tags]    compose    negative
    ${compose test file}=    Set Variable    ./compose-test-9.yaml
    Start compose from    ${compose test file}
    Verify response for unauthenticated request with    7100    *Unauthorized*
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7102    *Unauthorized*
    Verify response for authenticated request with    7100    *Query Console*
    Verify response for authenticated request with    7101    *No license key has been entered*
    Verify response for authenticated request with    7102    *Monitoring Dashboard*
    IF    'rootless' not in '${IMAGE_TYPE}'
        Compose logs should contain    ${compose test file}    *bootstrap*TZ is defined, setting timezone to America/Los_Angeles.*
    END
    Compose logs should contain    ${compose test file}    *bootstrap*MARKLOGIC_ADMIN_PASSWORD is set, using ENV for admin password.*
    Compose logs should contain    ${compose test file}    *bootstrap*MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Compose logs should contain    ${compose test file}    *bootstrap*MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
    IF    'rootless' not in '${IMAGE_TYPE}'
        Compose logs should contain    ${compose test file}    *node2*TZ is defined, setting timezone to America/Los_Angeles.*
    END
    Compose logs should contain    ${compose test file}    *node2*MARKLOGIC_ADMIN_PASSWORD is set, using ENV for admin password.*
    Compose logs should contain    ${compose test file}    *node2*MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Compose logs should contain    ${compose test file}    *node2*Bootstrap host node1 not found. Please verify the configuration, exiting*
    Host count on port 7102 should be 1

    [Teardown]    Delete compose from    ${compose test file}
    
Two node compose with credentials in env and verify restart logic
    [Tags]    compose
    ${compose test file}=    Set Variable    ./compose-test-3.yaml
    Start compose from    ${compose test file}
    Verify response for unauthenticated request with    7100    *Unauthorized*
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7102    *Unauthorized*
    Verify response for unauthenticated request with    7200    *Unauthorized*
    Verify response for unauthenticated request with    7201    *Unauthorized*
    Verify response for unauthenticated request with    7202    *Unauthorized*
    Verify response for authenticated request with    7100    *Query Console*
    Verify response for authenticated request with    7101    *No license key has been entered*
    Verify response for authenticated request with    7102    *Monitoring Dashboard*
    Verify response for authenticated request with    7200    *Query Console*
    Verify response for authenticated request with    7201    *No license key has been entered*
    Verify response for authenticated request with    7202    *Monitoring Dashboard*
    Host count on port 7102 should be 2
    Host count on port 7202 should be 2

    Compose logs should contain    ${compose test file}    *bootstrap*MARKLOGIC_ADMIN_PASSWORD is set, using ENV for admin password.*
    Compose logs should contain    ${compose test file}    *bootstrap*MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Compose logs should contain    ${compose test file}    *bootstrap*MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
    Verify container timezone    America/Los_Angeles    port=7100
    Verify container timezone    America/Los_Angeles    port=7200
    IF    'rootless' not in '${IMAGE_TYPE}'
        Compose logs should contain    ${compose test file}    *bootstrap*TZ is defined, setting timezone to America/Los_Angeles.*
        Compose logs should contain    ${compose test file}    *node2*TZ is defined, setting timezone to America/Los_Angeles.*
    END
    Compose logs should contain    ${compose test file}    *node2*MARKLOGIC_ADMIN_PASSWORD is set, using ENV for admin password.*
    Compose logs should contain    ${compose test file}    *node2*MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Compose logs should contain    ${compose test file}    *node2*MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
    Restart compose from    ${compose test file}
    Compose logs should contain    ${compose test file}    *bootstrap*MARKLOGIC_INIT is true, but the server is already initialized. Skipping initialization.*
    Compose logs should contain    ${compose test file}    *node2*MARKLOGIC_INIT is true, but the server is already initialized. Skipping initialization.*
    Verify container timezone    America/Los_Angeles    port=7100
    Verify container timezone    America/Los_Angeles    port=7200
    [Teardown]    Delete compose from    ${compose test file}

Two node compose with second node uncoupled
    [Tags]    compose
    Start compose from    ./compose-test-4.yaml
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7201    *Unauthorized*
    Host count on port 7102 should be 1
    Host count on port 7202 should be 1
    [Teardown]    Delete compose from    ./compose-test-4.yaml

Two node compose with second node uninitialized
    [Tags]    compose
    Start compose from    ./compose-test-5.yaml
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7201    *This server must now self-install the initial databases and application servers. Click OK to continue.*
    Host count on port 7102 should be 1
    Verify response for authenticated request with    7200    *Forbidden*
    Verify response for authenticated request with    7201    *This server must now self-install the initial databases and application servers. Click OK to continue.*
    Verify response for authenticated request with    7202    *Forbidden*
    [Teardown]    Delete compose from    ./compose-test-5.yaml

Initialized MarkLogic Server with wallet password and realm
    Create container with    -e    MARKLOGIC_INIT=true
    ...                      -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                      -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    ...                      -e    MARKLOGIC_WALLET_PASSWORD=test_wallet_pass
    ...                      -e    REALM=public
    Verify response for unauthenticated request with    8000    *Unauthorized*
    Verify response for unauthenticated request with    8001    *Unauthorized*
    Verify response for unauthenticated request with    8002    *Unauthorized*
    Verify response for authenticated request with    8000    *Query Console*
    Verify response for authenticated request with    8001/security-admin.xqy?section=security    *public*
    Verify response for authenticated request with    8002    *Monitoring Dashboard*
    [Teardown]    Delete container

Initialized MarkLogic container with ML converters
    Create container with    -e    MARKLOGIC_INIT=true
    ...                      -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                      -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    ...                      -e    INSTALL_CONVERTERS=true
    Docker log should contain    *INSTALL_CONVERTERS is true, installing converters.*
    Docker log should contain    *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    MarkLogic Error log should contain    .*Info: MarkLogic Converters.*found
    Verify converter package installation
    [Teardown]    Delete container
 
Dynamic Host Cluster Test
    [Tags]    dynamic-hosts
    ${major_version}=    Set Variable    ${MARKLOGIC_VERSION.split('.')[0]}
    Skip If    '${major_version}' == '' or '${major_version}' == 'None' or int('${major_version}' or '0') < 12    msg=Dynamic Host Concurrency Test requires MarkLogic 12 or higher (current version: ${MARKLOGIC_VERSION})
    Start compose from    compose-test-16.yaml
    # give it some time to prepare the large cluster
    Sleep    60s
    ${group}=    set Variable    dynamic
    Set up dynamic host group ${group}
    Enable API token authentication on 7202 for group Default
    Dynamic Host Join Successful on ${group} with 7401
    Dynamic Host Join Failure on dynamic with 7501 with wrong token
    Dynamic Host Join Failure on dynamic with 7501 when feature disabled
    Dynamic Host Join Failure on ${group} with 7501 when not using the Admin app server
    Dynamic Host Remove Successful When Host is down
    Dynamic Host Join Successful on ${group} with 7601
    Dynamic Host Remove Successful When All Node is up
    Dynamic Host Added When Some Host is down 7701
    Dynamic Host Join Successful on dynamic with 7801
    Dynamic Host Returns All Id dynamic4
    Verify Full Cluster Restart Removes Dynamic Host Configuration dynamic
    Enable dynamic host feature on 7102 for group Default
    Dynamic Host Join Successful with d-node on Default with 7901
    Disable dynamic host feature on 7102 for group Default
    Verify Dynamic Host Count on port 7102 for group Default equals 1
    Enable dynamic host feature on 7102 for group Default
    Dynamic Host Join Fails When Token Expires ${group}
    Dynamic Host Join Fails After Token Revoked ${group}
    Verify Dynamic Host Can Execute Query Default 7902
    [Teardown]    Delete compose from    compose-test-16.yaml

Dynamic Host Cluster Concurrecy Join Test
    [Tags]    dynamic-hosts
    ${major_version}=    Set Variable    ${MARKLOGIC_VERSION.split('.')[0]}
    Skip If    '${major_version}' == '' or '${major_version}' == 'None' or int('${major_version}' or '0') < 12    msg=Dynamic Host Concurrency Test requires MarkLogic 12 or higher (current version: ${MARKLOGIC_VERSION})
    Start compose from    compose-test-16.yaml
    # give it some time to prepare the large cluster
    Sleep    60s
    ${group}=    set Variable    dynamic
    Set up dynamic host group ${group}
    Enable API token authentication on 7202 for group Default
    Concurrent Dynamic Host Join Test

    [Teardown]    Delete compose from    compose-test-16.yaml

Verify parameter overrides
    Create container with    -e    OVERWRITE_ML_CONF=true
    ...                      -e    TZ=America/Los_Angeles
    ...                      -e    MARKLOGIC_PID_FILE=/tmp/MarkLogic.pid.test
    ...                      -e    MARKLOGIC_UMASK=022
    ...                      -e    ML_HUGEPAGES_TOTAL=0
    ...                      -e    MARKLOGIC_DISABLE_JVM=true
    ...                      -e    MARKLOGIC_USER=marklogic_user
    ...                      -e    JAVA_HOME=fakejava
    ...                      -e    CLASSPATH=fakeclasspath
    ...                      -e    MARKLOGIC_EC2_HOST=false

    IF    'rootless' not in '${IMAGE_TYPE}'
        Docker log should contain    *OVERWRITE_ML_CONF is true, deleting existing /etc/marklogic.conf and overwriting with ENV variables.*
        Docker log should contain    *TZ is defined, setting timezone to America/Los_Angeles.*
    END
    Verify That marklogic.conf contains    TZ=America/Los_Angeles    MARKLOGIC_PID_FILE=/tmp/MarkLogic.pid.test    MARKLOGIC_UMASK=022    ML_HUGEPAGES_TOTAL=0    MARKLOGIC_DISABLE_JVM=true    MARKLOGIC_USER=marklogic_user    JAVA_HOME=fakejava    CLASSPATH=fakeclasspath    MARKLOGIC_EC2_HOST=false
    [Teardown]    Delete container

Verify implicit parameter overrides
    Create container with    -e    TZ=America/Los_Angeles
    ...                      -e    MARKLOGIC_PID_FILE=/tmp/MarkLogic.pid.test
    ...                      -e    MARKLOGIC_UMASK=022
    ...                      -e    ML_HUGEPAGES_TOTAL=0
    ...                      -e    MARKLOGIC_DISABLE_JVM=true
    ...                      -e    MARKLOGIC_USER=marklogic_user
    ...                      -e    JAVA_HOME=fakejava
    ...                      -e    CLASSPATH=fakeclasspath
    ...                      -e    MARKLOGIC_EC2_HOST=false

    IF    'rootless' not in '${IMAGE_TYPE}'
        Docker log should contain    *OVERWRITE_ML_CONF is true, deleting existing /etc/marklogic.conf and overwriting with ENV variables.*
        Docker log should contain    *TZ is defined, setting timezone to America/Los_Angeles.*
    END
    Verify That marklogic.conf contains    TZ=America/Los_Angeles    MARKLOGIC_PID_FILE=/tmp/MarkLogic.pid.test    MARKLOGIC_UMASK=022    ML_HUGEPAGES_TOTAL=0    MARKLOGIC_DISABLE_JVM=true    MARKLOGIC_USER=marklogic_user    JAVA_HOME=fakejava    CLASSPATH=fakeclasspath    MARKLOGIC_EC2_HOST=false
    [Teardown]    Delete container
    