# Copyright © 2018-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
*** Settings ***
Resource         keywords.resource
Documentation    Test all initialization options using Docker run and Docker Compose.
...              Each test case creates and then tears down one or more Docker containers.
...              Verification is done using REST calls to MarkLogic server and Docker logs.
Suite Setup      Ensure Test Results Directory Exists

*** Test Cases ***

D01 Smoke Test
    [Tags]    docker-run    D01    positive
    [Documentation]    Detailed scenario: Smoke Test.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Create container with
    Docker log should contain    *MARKLOGIC_INIT is set to false or not defined, not initializing.*
    [Teardown]    Delete container

D02 Uninit ML container
    [Tags]    docker-run    D02    positive
    [Documentation]    Detailed scenario: Uninitialized MarkLogic container.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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

D03 Uninit ML container w/ no params
    [Tags]    docker-run    D03    positive
    [Documentation]    Detailed scenario: Uninitialized MarkLogic container with no parameters.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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

D04 Init ML container
    [Tags]    docker-run    D04    positive
    [Documentation]    Detailed scenario: Initialized MarkLogic container.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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

D05 Init ML container w/ latency
    [Tags]    docker-run    D05    positive    long_running
    [Documentation]    This test verifies the initialization of the MarkLogic container with high latency. Detailed scenario: Initialized MarkLogic container with latency.
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

D06 Upgrade ML container
    [Tags]    docker-run    D06    positive
    [Documentation]    Detailed scenario: Upgrade MarkLogic container.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Skip If    'rootless' in '${IMAGE_TYPE}'    msg = Skipping Upgrade MarkLogic test for rootless image
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

D07 Upgrade ML container w/ init param
    [Tags]    docker-run    D07    positive
    [Documentation]    Detailed scenario: Upgrade MarkLogic container with init parameter.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Skip If    'rootless' in '${IMAGE_TYPE}'    msg = Skipping Upgrade MarkLogic test for rootless image
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

D08 Upgrade ML container w/ init & credential
    [Tags]    docker-run    D08    positive
    [Documentation]    Detailed scenario: Upgrade MarkLogic container with init and credential parameters.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Skip If    'rootless' in '${IMAGE_TYPE}'    msg = Skipping Upgrade MarkLogic test for rootless image
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

D09 Init ML container w/ admin password
    [Tags]    docker-run    D09    positive
    [Documentation]    Detailed scenario: Initialized MarkLogic container with admin password containing special characters.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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

D10 Init ML container w/ license key installed
    [Tags]    docker-run    D10    positive
    [Documentation]    Detailed scenario: Initialized MarkLogic container with license key installed and MARKLOGIC_INIT set to TRUE.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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

D11 Init ML container w/o creds
    [Tags]    docker-run    D11    negative
    [Documentation]    Detailed scenario: Initialized MarkLogic container without credentials.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Create failing container with    -e    MARKLOGIC_INIT=true
    Docker log should contain    *MARKLOGIC_ADMIN_USERNAME and MARKLOGIC_ADMIN_PASSWORD must be set.*
    [Teardown]    Delete container

D12 Init ML container w/ invalid value
    [Tags]    docker-run    D12    negative
    [Documentation]    Detailed scenario: Initialized MarkLogic container with invalid value for MARKLOGIC_JOIN_CLUSTER.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Create failing container with    -e    MARKLOGIC_INIT=true
    ...                              -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                              -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    ...                              -e    MARKLOGIC_JOIN_CLUSTER=invalid
    Docker log should contain    *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    Docker log should contain    *Error: MARKLOGIC_JOIN_CLUSTER must be true or false.*
    [Teardown]    Delete container

D13 Invalid value for INIT
    [Tags]    docker-run    D13    negative
    [Documentation]    Detailed scenario: Invalid value for INIT.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Create failing container with    -e    MARKLOGIC_INIT=invalid
    ...                              -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                              -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    Docker log should contain    *Error: MARKLOGIC_INIT must be true or false.*
    [Teardown]    Delete container

D14 Invalid value for HOSTNAME
    [Tags]    docker-run    D14    negative
    [Documentation]    Detailed scenario: Invalid value for HOSTNAME.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Create failing container with    -e    HOSTNAME=invalid_hostname
    ...                              -e    MARKLOGIC_INIT=true
    ...                              -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                              -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    Docker log should contain    *Error: Failed to restart invalid_hostname*
    [Teardown]    Delete container

D15 Init ML container w/o config overrides
    [Tags]    docker-run    D15    positive
    [Documentation]    Detailed scenario: Initialized MarkLogic container without config overrides.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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

D16 Init ML container w/ config overrides
    [Tags]    docker-run    D16    positive
    [Documentation]    Detailed scenario: Initialized MarkLogic container with config overrides.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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

C01 Single node compose test
    [Tags]    compose    C01    positive
    [Documentation]    Detailed scenario: Single node compose example.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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

C02 Single node compose special secrets
    [Tags]    compose    C02    positive
    [Documentation]    Detailed scenario: Single node compose example with special characters in secrets file.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Start compose from    ../docker-compose/marklogic-single-node.yaml    ${SPEC CHARS ADMIN PASS}
    Verify response for unauthenticated request with    8000    *Unauthorized*
    Verify response for unauthenticated request with    8001    *Unauthorized*
    Verify response for unauthenticated request with    8002    *Unauthorized*
    Verify response for authenticated request with    8000    *Query Console*    ${SPEC CHARS ADMIN PASS}
    Verify response for authenticated request with    8001    *No license key has been entered*    ${SPEC CHARS ADMIN PASS}
    Verify response for authenticated request with    8002    *Monitoring Dashboard*    ${SPEC CHARS ADMIN PASS}
    [Teardown]    Delete compose from    ../docker-compose/marklogic-single-node.yaml

C03 Single node compose special yaml
    [Tags]    compose    C03    positive
    [Documentation]    Detailed scenario: Single node compose with special characters in yaml.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Start compose from    ./compose-test-1.yaml    ${SPEC CHARS ADMIN PASS}
    Verify response for unauthenticated request with    7100    *Unauthorized*
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7102    *Unauthorized*
    Verify response for authenticated request with    7100    *Query Console*    ${SPEC CHARS ADMIN PASS}
    Verify response for authenticated request with    7101    *No license key has been entered*    ${SPEC CHARS ADMIN PASS}
    Verify response for authenticated request with    7102    *Monitoring Dashboard*    ${SPEC CHARS ADMIN PASS}
    [Teardown]    Delete compose from    ./compose-test-1.yaml

C04 Three node compose cluster
    [Tags]    compose    C04    positive
    [Documentation]    Detailed scenario: Three node compose example.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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

C05 Two node compose enode join
    [Tags]    compose    C05    positive
    [Documentation]    Detailed scenario: Two node compose example with node joining enode group.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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
C06 Compose join HTTPS invalid params
    [Tags]    compose    C06    negative
    [Documentation]    Detailed scenario: Compose example with node joining cluster using https with invalid parameter values.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Create invalid certificate file
    Start compose from    ./compose-test-10.yaml    readiness=False
    Compose logs should contain    ./compose-test-10.yaml    *MARKLOGIC_JOIN_TLS_ENABLED must be set to true or false, please review the configuration. Container shutting down.*
    [Teardown]    Delete compose from    ./compose-test-10.yaml

C07 Compose join HTTPS missing cert param
    [Tags]    compose    C07    negative
    [Documentation]    Detailed scenario: Compose example with node joining cluster using https and missing certificate parameter.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Start compose from    ./compose-test-11.yaml    readiness=False
    Compose logs should contain    ./compose-test-11.yaml    *MARKLOGIC_JOIN_CACERT_FILE is not set, please review the configuration. Container shutting down.*
    [Teardown]    Delete compose from    ./compose-test-11.yaml

C08 Compose bootstrap SSL mismatch
    [Tags]    compose    C08    negative
    [Documentation]    Detailed scenario: Two node compose example with bootstrap node without SSL enabled and node joining cluster using https.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Start compose from    ./compose-test-1.yaml
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7102    *Unauthorized*
    Verify response for authenticated request with    7100    *Query Console*
    Verify response for authenticated request with    7101    *No license key has been entered*
    Verify response for authenticated request with    7102    *Monitoring Dashboard*
    Create invalid certificate file
    Start compose from    ./compose-test-2.yaml    readiness=False
    Compose logs should contain    ./compose-test-2.yaml    *TLS is not enabled on bootstrap_host_name host, please verify the configuration. Container shutting down.*
    [Teardown]    Run keywords    
    ...    Delete compose from    ./compose-test-1.yaml
    ...    AND    Delete compose from    ./compose-test-2.yaml

C09 Compose join invalid CA cert
    [Tags]    compose    C09    negative
    [Documentation]    Detailed scenario: Two node compose example with node joining cluster using invalid CAcertificate.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Start compose from    ./compose-test-1.yaml
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for authenticated request with    7101    *No license key has been entered*
    Add certificate template on bootstrap host    ./test_template.json    7102
    Get CAcertificate for testTemplate 7100
    Apply certificate testTemplate on App Server Admin 7102
    Apply certificate testTemplate on App Server Manage 7102
    Create invalid certificate file
    Start compose from    ./compose-test-2.yaml    readiness=False
    Compose logs should contain    ./compose-test-2.yaml    *MARKLOGIC_JOIN_CACERT_FILE is not valid, please check above error for details. Node shutting down.*
    [Teardown]    Run keywords    
    ...    Delete compose from    ./compose-test-1.yaml
    ...    AND    Delete compose from    ./compose-test-2.yaml

C10 Compose join HTTPS success
    [Tags]    compose    C10    positive
    [Documentation]    Detailed scenario: Two node compose example with node joining cluster using https.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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

C11 Compose bootstrap self-join
    [Tags]    compose    C11    negative
    [Documentation]    Detailed scenario: Single node compose example with bootstrap node joining trying to itself.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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
    
C12 Compose incorrect bootstrap host
    [Tags]    compose    C12    negative
    [Documentation]    Detailed scenario: Two node compose example with incorrect bootstrap host name.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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
    
C13 Compose creds env restart logic
    [Tags]    compose    C13    positive
    [Documentation]    Detailed scenario: Two node compose with credentials in env and verify restart logic.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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

C14 Compose second node uncoupled
    [Tags]    compose    C14    positive
    [Documentation]    Detailed scenario: Two node compose with second node uncoupled.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Start compose from    ./compose-test-4.yaml
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7201    *Unauthorized*
    Host count on port 7102 should be 1
    Host count on port 7202 should be 1
    [Teardown]    Delete compose from    ./compose-test-4.yaml

C15 Compose second node uninitialized
    [Tags]    compose    C15    positive
    [Documentation]    Detailed scenario: Two node compose with second node uninitialized.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Start compose from    ./compose-test-5.yaml
    Verify response for unauthenticated request with    7101    *Unauthorized*
    Verify response for unauthenticated request with    7201    *This server must now self-install the initial databases and application servers. Click OK to continue.*
    Host count on port 7102 should be 1
    Verify response for authenticated request with    7200    *Forbidden*
    Verify response for authenticated request with    7201    *This server must now self-install the initial databases and application servers. Click OK to continue.*
    Verify response for authenticated request with    7202    *Forbidden*
    [Teardown]    Delete compose from    ./compose-test-5.yaml

D17 Init ML Server w/ wallet password & realm
    [Tags]    docker-run    D17    positive
    [Documentation]    Detailed scenario: Initialized MarkLogic Server with wallet password and realm.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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

D18 Init ML container w/ ML converters
    [Tags]    docker-run    D18    positive
    [Documentation]    Detailed scenario: Initialized MarkLogic container with ML converters.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    Create container with    -e    MARKLOGIC_INIT=true
    ...                      -e    MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
    ...                      -e    MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
    ...                      -e    INSTALL_CONVERTERS=true
    Docker log should contain    *INSTALL_CONVERTERS is true, installing converters.*
    Docker log should contain    *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
    MarkLogic Error log should contain    .*Info: MarkLogic Converters.*found
    Verify converter package installation
    [Teardown]    Delete container
 
C16 Dynamic Host cluster flow
    [Tags]    compose    C16    positive    dynamic-hosts
    [Documentation]    Detailed scenario: Dynamic Host Cluster Test.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    ${major_version}=    Set Variable    ${MARKLOGIC_VERSION.split('.')[0]}
    Skip If    '${major_version}' == '' or '${major_version}' == 'None' or int('${major_version}' or '0') < 12    msg=Dynamic Host Concurrency Test requires MarkLogic 12 or higher (current version: ${MARKLOGIC_VERSION})
    Start compose from    ./compose-test-16.yaml
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
    Delete Token By JTI Succeeds on ${group}
    Verify Decoded Tokens Contain Fields on port 7102
    Delete Token By Invalid JTI on port 7102
    Delete Token By Host ID Succeeds on ${group}
    Delete Token By Invalid Host ID on port 7102
    Verify Invalid Cluster Name Returns 404 on port 7102
    Verify Dynamic Host Can Execute Query Default 7902
    [Teardown]    Delete compose from    ./compose-test-16.yaml

C17 Coupled clusters cross-cluster API
    [Tags]    compose    C17    positive    dynamic-hosts    coupled-clusters
    [Documentation]    Tests that foreign cluster dynamic host endpoints return the expected cross-cluster responses: GET /dynamic-host-token=200(empty), POST /dynamic-host-token=400, and DELETE operations on foreign-cluster resources=404 Detailed scenario: Coupled Clusters Cross-Cluster API Test.
    ${major_version}=    Set Variable    ${MARKLOGIC_VERSION.split('.')[0]}
    Skip If    '${major_version}' == '' or '${major_version}' == 'None' or int('${major_version}' or '0') < 12    msg=Coupled Clusters Test requires MarkLogic 12 or higher (current version: ${MARKLOGIC_VERSION})
    
    # Start two separate clusters
    Start compose from    ./compose-test-17.yaml
    
    # Get cluster names
    ${cluster1_name}=    Get Local Cluster Name on port 7102
    ${cluster2_name}=    Get Local Cluster Name on port 7302
    Log    Cluster 1 name: ${cluster1_name}
    Log    Cluster 2 name: ${cluster2_name}
    
    # Couple the two clusters (bidirectional)
    ${foreign_name}=    Couple Cluster on port 7102 with Foreign Cluster on port 7302
    Log    Cluster 1 coupled with foreign cluster: ${foreign_name}
    ${foreign_name}=    Couple Cluster on port 7302 with Foreign Cluster on port 7102
    Log    Cluster 2 coupled with foreign cluster: ${foreign_name}
    
    # Enable dynamic host feature and API token auth on both clusters (required for token creation)
    Enable dynamic host feature on 7102 for group Default
    Enable API token authentication on 7102 for group Default
    Enable dynamic host feature on 7302 for group Default
    Enable API token authentication on 7302 for group Default

    # Test 1: From Cluster 1, try to access Cluster 2's dynamic host token API - should return 400
    Verify Cross Cluster API Returns Error on port 7102 for cluster ${cluster2_name}

    # Test 2: From Cluster 2, try to access Cluster 1's dynamic host token API - should return 400
    Verify Cross Cluster API Returns Error on port 7302 for cluster ${cluster1_name}

    Log    Successfully verified coupled cluster API behaviour: GET /dynamic-host-token=200(empty), POST /dynamic-host-token=400, DELETE /dynamic-host-token/{real-jti}=404, DELETE /dynamic-hosts/{real-host-id}=404
    
    [Teardown]    Delete compose from    ./compose-test-17.yaml

C18 Dynamic Host concurrent join
    [Tags]    compose    C18    positive    dynamic-hosts
    [Documentation]    Detailed scenario: Dynamic Host Cluster Concurrency Join Test.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
    ${major_version}=    Set Variable    ${MARKLOGIC_VERSION.split('.')[0]}
    Skip If    '${major_version}' == '' or '${major_version}' == 'None' or int('${major_version}' or '0') < 12    msg=Dynamic Host Concurrency Test requires MarkLogic 12 or higher (current version: ${MARKLOGIC_VERSION})
    Start compose from    ./compose-test-16.yaml
    # give it some time to prepare the large cluster
    Sleep    60s
    ${group}=    set Variable    dynamic
    Set up dynamic host group ${group}
    Enable API token authentication on 7202 for group Default
    Concurrent Dynamic Host Join Test

    [Teardown]    Delete compose from    ./compose-test-16.yaml

D19 Verify param overrides
    [Tags]    docker-run    D19    positive
    [Documentation]    Detailed scenario: Verify parameter overrides.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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

D20 Verify implicit param overrides
    [Tags]    docker-run    D20    positive
    [Documentation]    Detailed scenario: Verify implicit parameter overrides.
    ...                Covers setup, execution, and expected outcome validation for this scenario.
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
    
