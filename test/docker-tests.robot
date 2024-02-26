*** Settings ***
Resource       keywords.resource
Documentation  Test all initialization options using Docker run and Docker Compose.
...            Each test case creates and then tears down one or more Docker containers.
...            Verification is done using REST calls to MarkLogic server and Docker logs.

*** Test Cases ***
Uninitialized MarkLogic container
  Create container with  -e  MARKLOGIC_INIT=false
  Docker log should contain  *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
  Docker log should contain  *MARKLOGIC_INIT is set to false or not defined, not initializing.*
  Docker log should contain  *Starting MarkLogic container with ${MARKLOGIC_VERSION} from ${BUILD_BRANCH}*
  Verify response for unauthenticated request with  8000  *Forbidden*
  Verify response for unauthenticated request with  8001  *This server must now self-install the initial databases and application servers. Click OK to continue.*
  Verify response for unauthenticated request with  8002  *Forbidden*
  Verify response for authenticated request with  8000  *Forbidden*
  Verify response for authenticated request with  8001  *This server must now self-install the initial databases and application servers. Click OK to continue.*
  Verify response for authenticated request with  8002  *Forbidden*
  [Teardown]  Delete container

Initialized MarkLogic container
  Create container with  -e  MARKLOGIC_INIT=true
  ...                    -e  MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
  ...                    -e  MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
  Docker log should contain  *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
  Docker log should contain  *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
  Docker log should contain  *Starting MarkLogic container with ${MARKLOGIC_VERSION} from ${BUILD_BRANCH}*
  Verify response for unauthenticated request with  8000  *Unauthorized*
  Verify response for unauthenticated request with  8001  *Unauthorized*
  Verify response for unauthenticated request with  8002  *Unauthorized*
  Verify response for authenticated request with  8000  *Query Console*
  Verify response for authenticated request with  8001  *No license key has been entered*
  Verify response for authenticated request with  8002  *Monitoring Dashboard*
  [Teardown]  Delete container

Initialized MarkLogic container with admin password containing special characters
  Create container with  -e  MARKLOGIC_INIT=true
  ...                    -e  MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
  ...                    -e  MARKLOGIC_ADMIN_PASSWORD=${SPEC CHARS ADMIN PASS}
  Docker log should contain  *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
  Docker log should contain  *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
  Docker log should contain  *Starting MarkLogic container with ${MARKLOGIC_VERSION} from ${BUILD_BRANCH}*
  Verify response for unauthenticated request with  8000  *Unauthorized*
  Verify response for unauthenticated request with  8001  *Unauthorized*
  Verify response for unauthenticated request with  8002  *Unauthorized*
  Verify response for authenticated request with  8000  *Query Console*  ${SPEC CHARS ADMIN PASS}
  Verify response for authenticated request with  8001  *No license key has been entered*  ${SPEC CHARS ADMIN PASS}
  Verify response for authenticated request with  8002  *Monitoring Dashboard*  ${SPEC CHARS ADMIN PASS}
  [Teardown]  Delete container

Initialized MarkLogic container with license key installed and MARKLOGIC_INIT set to TRUE
  Create container with  -e  MARKLOGIC_INIT=TRUE
  ...                    -e  MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
  ...                    -e  MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
  ...                    -e  LICENSEE=${LICENSEE}
  ...                    -e  LICENSE_KEY=${LICENSE KEY}
  Docker log should contain  *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
  Docker log should contain  *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
  Verify response for unauthenticated request with  8000  *Unauthorized*
  Verify response for unauthenticated request with  8001  *Unauthorized*
  Verify response for unauthenticated request with  8002  *Unauthorized*
  Verify response for authenticated request with  8000  *Query Console*
  Verify response for authenticated request with  8001/license.xqy  *MarkLogic - Version 9 QA Test License*
  Verify response for authenticated request with  8002  *Monitoring Dashboard*
  [Teardown]  Delete container

Initialized MarkLogic container without credentials
  [Tags]  negative
  Create failing container with  -e  MARKLOGIC_INIT=true
  Docker log should contain  *MARKLOGIC_ADMIN_USERNAME and MARKLOGIC_ADMIN_PASSWORD must be set.*
  [Teardown]  Delete container

Initialized MarkLogic container with invalid value for MARKLOGIC_JOIN_CLUSTER
  Create failing container with  -e  MARKLOGIC_INIT=true
  ...                    -e  MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
  ...                    -e  MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
  ...                    -e  MARKLOGIC_JOIN_CLUSTER=invalid
  Docker log should contain  *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
  Docker log should contain  *Error: MARKLOGIC_JOIN_CLUSTER must be true or false.*
  [Teardown]  Delete container

Invalid value for INIT
  Create failing container with  -e  MARKLOGIC_INIT=invalid
  ...                    -e  MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
  ...                    -e  MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
  Docker log should contain  *Error: MARKLOGIC_INIT must be true or false.*
  [Teardown]  Delete container

Invalid value for HOSTNAME
  Create failing container with  -e  HOSTNAME=invalid_hostname
  ...                    -e  MARKLOGIC_INIT=true
  ...                    -e  MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
  ...                    -e  MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
  Docker log should contain  *Error: Failed to restart invalid_hostname*
  [Teardown]  Delete container

Initialized MarkLogic container with config overrides
  Create container with  -e  MARKLOGIC_INIT=true
  ...                    -e  OVERWRITE_ML_CONF=true
  ...                    -e  TZ=America/Los_Angeles
  ...                    -e  MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
  ...                    -e  MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
  Docker log should contain  *OVERWRITE_ML_CONF is true, deleting existing /etc/marklogic.conf and overwriting with ENV variables.*
  Docker log should contain  *INSTALL_CONVERTERS is false, not installing converters.*
  Docker log should contain  *TZ is defined, setting timezone to America/Los_Angeles.*
  Docker log should contain  *MARKLOGIC_INIT is true, initializing the MarkLogic server.*
  Verify response for unauthenticated request with  8000  *Unauthorized*
  Verify response for unauthenticated request with  8001  *Unauthorized*
  Verify response for unauthenticated request with  8002  *Unauthorized*
  Verify response for authenticated request with  8000  *Query Console*
  Verify response for authenticated request with  8001  *No license key has been entered*
  Verify response for authenticated request with  8002  *Monitoring Dashboard*
  [Teardown]  Delete container

Single node compose example
  Start compose from  ../docker-compose/marklogic-single-node.yaml
  Verify response for unauthenticated request with  8000  *Unauthorized*
  Verify response for unauthenticated request with  8001  *Unauthorized*
  Verify response for unauthenticated request with  8002  *Unauthorized*
  Verify response for authenticated request with  8000  *Query Console*
  Verify response for authenticated request with  8001  *No license key has been entered*
  Verify response for authenticated request with  8002  *Monitoring Dashboard*
  Compose logs should contain  ../docker-compose/marklogic-single-node.yaml  *TZ is defined, setting timezone to Europe/Prague.*
  Host count on port 8002 should be 1
  [Teardown]  Delete compose from  ../docker-compose/marklogic-single-node.yaml

Single node compose example with special characters in secrets file
  Start compose from  ../docker-compose/marklogic-single-node.yaml  ${SPEC CHARS ADMIN PASS}
  Verify response for unauthenticated request with  8000  *Unauthorized*
  Verify response for unauthenticated request with  8001  *Unauthorized*
  Verify response for unauthenticated request with  8002  *Unauthorized*
  Verify response for authenticated request with  8000  *Query Console*  ${SPEC CHARS ADMIN PASS}
  Verify response for authenticated request with  8001  *No license key has been entered*  ${SPEC CHARS ADMIN PASS}
  Verify response for authenticated request with  8002  *Monitoring Dashboard*  ${SPEC CHARS ADMIN PASS}
  [Teardown]  Delete compose from  ../docker-compose/marklogic-single-node.yaml

Single node compose with special characters in yaml
  Start compose from  ../test/compose-test-1.yaml  ${SPEC CHARS ADMIN PASS}
  Verify response for unauthenticated request with  7100  *Unauthorized*
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for unauthenticated request with  7102  *Unauthorized*
  Verify response for authenticated request with  7100  *Query Console*  ${SPEC CHARS ADMIN PASS}
  Verify response for authenticated request with  7101  *No license key has been entered*  ${SPEC CHARS ADMIN PASS}
  Verify response for authenticated request with  7102  *Monitoring Dashboard*  ${SPEC CHARS ADMIN PASS}
  [Teardown]  Delete compose from  ../test/compose-test-1.yaml

Three node compose example
  Start compose from  ../docker-compose/marklogic-multi-node.yaml
  Verify response for unauthenticated request with  7100  *Unauthorized*
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for unauthenticated request with  7102  *Unauthorized*
  Verify response for unauthenticated request with  7200  *Unauthorized*
  Verify response for unauthenticated request with  7201  *Unauthorized*
  Verify response for unauthenticated request with  7202  *Unauthorized*
  Verify response for unauthenticated request with  7300  *Unauthorized*
  Verify response for unauthenticated request with  7301  *Unauthorized*
  Verify response for unauthenticated request with  7302  *Unauthorized*
  Verify response for authenticated request with  7100  *Query Console*
  Verify response for authenticated request with  7101  *No license key has been entered*
  Verify response for authenticated request with  7102  *Monitoring Dashboard*
  Verify response for authenticated request with  7200  *Query Console*
  Verify response for authenticated request with  7201  *No license key has been entered*
  Verify response for authenticated request with  7202  *Monitoring Dashboard*
  Verify response for authenticated request with  7300  *Query Console*
  Verify response for authenticated request with  7301  *No license key has been entered*
  Verify response for authenticated request with  7302  *Monitoring Dashboard*
  Host count on port 7102 should be 3
  Host count on port 7202 should be 3
  Host count on port 7302 should be 3
  [Teardown]  Delete compose from  ../docker-compose/marklogic-multi-node.yaml

Two node compose example with node joining enode group
  Start compose from  ./compose-test-6.yaml
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for unauthenticated request with  7102  *Unauthorized*
  Verify response for authenticated request with  7100  *Query Console*
  Verify response for authenticated request with  7101  *No license key has been entered*
  Verify response for authenticated request with  7102  *Monitoring Dashboard*
  Add group enode on host on port 7102
  Start compose from  ./compose-test-7.yaml  readiness=False
  Compose logs should contain  ./compose-test-7.yaml  *Cluster config complete, marking this container as ready.*
  Host node2 should be part of group enode
  [Teardown]  Run keywords  
  ...  Delete compose from  ./compose-test-6.yaml
  ...  AND  Delete compose from  ./compose-test-7.yaml

# Tests for invalid certificate/CA, invalid  value for MARKLOGIC_JOIN_TLS_ENABLED 
Compose example with node joining cluster using https with invalid parameter values
  Create invalid certificate file
  Start compose from  ./compose-test-10.yaml  readiness=False
  Compose logs should contain  ./compose-test-10.yaml  *MARKLOGIC_JOIN_TLS_ENABLED must be set to true or false, please review the configuration. Container shutting down.*
  [Teardown]  Delete compose from  ./compose-test-10.yaml

Compose example with node joining cluster using https and missing certificate parameter
  Start compose from  ./compose-test-11.yaml  readiness=False
  Compose logs should contain  ./compose-test-11.yaml  *MARKLOGIC_JOIN_CACERT_FILE is not set, please review the configuration. Container shutting down.*
  [Teardown]  Delete compose from  ./compose-test-11.yaml

Two node compose example with bootstrap node without SSL enabled and node joining cluster using https 
  Start compose from  ./compose-test-12.yaml
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for unauthenticated request with  7102  *Unauthorized*
  Verify response for authenticated request with  7100  *Query Console*
  Verify response for authenticated request with  7101  *No license key has been entered*
  Verify response for authenticated request with  7102  *Monitoring Dashboard*
  Create invalid certificate file
  Start compose from  ./compose-test-13.yaml  readiness=False
  Compose logs should contain  ./compose-test-13.yaml  *TLS is not enabled on bootstrap_host_name host, please verify the configuration. Container shutting down.*
  [Teardown]  Run keywords  
  ...  Delete compose from  ./compose-test-12.yaml
  ...  AND  Delete compose from  ./compose-test-13.yaml

Two node compose example with node joining cluster using invalid CAcertificate
  Start compose from  ./compose-test-14.yaml
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for authenticated request with  7101  *No license key has been entered*
  Add certificate template on bootstrap host  ./test_template.json  7102
  Get CAcertificate for testTemplate 7100
  Apply certificate testTemplate on App Server Admin 7102
  Apply certificate testTemplate on App Server Manage 7102
  Create invalid certificate file
  Start compose from  ./compose-test-15.yaml  readiness=False
  Compose logs should contain  ./compose-test-15.yaml  *MARKLOGIC_JOIN_CACERT_FILE is not valid, please check above error for details. Node shutting down.*
  [Teardown]  Run keywords  
  ...  Delete compose from  ./compose-test-14.yaml
  ...  AND  Delete compose from  ./compose-test-15.yaml

Two node compose example with node joining cluster using https
  Start compose from  ./compose-test-1.yaml
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for authenticated request with  7101  *No license key has been entered*
  Add certificate template on bootstrap host  ./test_template.json  7102
  Get CAcertificate for testTemplate 7100
  Apply certificate testTemplate on App Server Admin 7102
  Apply certificate testTemplate on App Server Manage 7102
  Start compose from  ./compose-test-2.yaml  readiness=False
  Compose logs should contain  ./compose-test-2.yaml  *Cluster config complete, marking this container as ready.*
  [Teardown]  Run keywords  
  ...  Delete compose from  ./compose-test-1.yaml
  ...  AND  Delete compose from  ./compose-test-2.yaml

Single node compose example with bootstrap node joining trying to itself
  Start compose from  ./compose-test-8.yaml
  Verify response for unauthenticated request with  7100  *Unauthorized*
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for unauthenticated request with  7102  *Unauthorized*
  Verify response for authenticated request with  7100  *Query Console*
  Verify response for authenticated request with  7101  *No license key has been entered*
  Verify response for authenticated request with  7102  *Monitoring Dashboard*
  Compose logs should contain  ./compose-test-8.yaml  *bootstrap*TZ is defined, setting timezone to America/Los_Angeles.*
  Compose logs should contain  ./compose-test-8.yaml  *bootstrap*MARKLOGIC_ADMIN_PASSWORD is set, using ENV for admin password.*
  Compose logs should contain  ./compose-test-8.yaml  *bootstrap*MARKLOGIC_INIT is true, initializing the MarkLogic server.*
  Compose logs should contain  ./compose-test-8.yaml  *bootstrap*HOST cannot join itself, skipped joining cluster.*
  Host count on port 7102 should be 1
  [Teardown]  Delete compose from  ./compose-test-8.yaml
  
Two node compose example with incorrect bootstrap host name
  Start compose from  ./compose-test-9.yaml
  Verify response for unauthenticated request with  7100  *Unauthorized*
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for unauthenticated request with  7102  *Unauthorized*
  Verify response for authenticated request with  7100  *Query Console*
  Verify response for authenticated request with  7101  *No license key has been entered*
  Verify response for authenticated request with  7102  *Monitoring Dashboard*
  Compose logs should contain  ./compose-test-9.yaml  *bootstrap*TZ is defined, setting timezone to America/Los_Angeles.*
  Compose logs should contain  ./compose-test-9.yaml  *bootstrap*MARKLOGIC_ADMIN_PASSWORD is set, using ENV for admin password.*
  Compose logs should contain  ./compose-test-9.yaml  *bootstrap*MARKLOGIC_INIT is true, initializing the MarkLogic server.*
  Compose logs should contain  ./compose-test-9.yaml  *bootstrap*MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
  Compose logs should contain  ./compose-test-9.yaml  *node2*TZ is defined, setting timezone to America/Los_Angeles.*
  Compose logs should contain  ./compose-test-9.yaml  *node2*MARKLOGIC_ADMIN_PASSWORD is set, using ENV for admin password.*
  Compose logs should contain  ./compose-test-9.yaml  *node2*MARKLOGIC_INIT is true, initializing the MarkLogic server.*
  Compose logs should contain  ./compose-test-9.yaml  *node2*Bootstrap host node1 not found. Please verify the configuration, exiting*
  Host count on port 7102 should be 1
  [Teardown]  Delete compose from  ./compose-test-9.yaml
  
Two node compose with credentials in env and verify restart logic
  Start compose from  ./compose-test-3.yaml
  Verify response for unauthenticated request with  7100  *Unauthorized*
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for unauthenticated request with  7102  *Unauthorized*
  Verify response for unauthenticated request with  7200  *Unauthorized*
  Verify response for unauthenticated request with  7201  *Unauthorized*
  Verify response for unauthenticated request with  7202  *Unauthorized*
  Verify response for authenticated request with  7100  *Query Console*
  Verify response for authenticated request with  7101  *No license key has been entered*
  Verify response for authenticated request with  7102  *Monitoring Dashboard*
  Verify response for authenticated request with  7200  *Query Console*
  Verify response for authenticated request with  7201  *No license key has been entered*
  Verify response for authenticated request with  7202  *Monitoring Dashboard*
  Host count on port 7102 should be 2
  Host count on port 7202 should be 2
  Compose logs should contain  ./compose-test-3.yaml  *bootstrap*TZ is defined, setting timezone to America/Los_Angeles.*
  Compose logs should contain  ./compose-test-3.yaml  *bootstrap*MARKLOGIC_ADMIN_PASSWORD is set, using ENV for admin password.*
  Compose logs should contain  ./compose-test-3.yaml  *bootstrap*MARKLOGIC_INIT is true, initializing the MarkLogic server.*
  Compose logs should contain  ./compose-test-3.yaml  *bootstrap*MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
  Compose logs should contain  ./compose-test-3.yaml  *node2*TZ is defined, setting timezone to America/Los_Angeles.*
  Compose logs should contain  ./compose-test-3.yaml  *node2*MARKLOGIC_ADMIN_PASSWORD is set, using ENV for admin password.*
  Compose logs should contain  ./compose-test-3.yaml  *node2*MARKLOGIC_INIT is true, initializing the MarkLogic server.*
  Compose logs should contain  ./compose-test-3.yaml  *node2*MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
  Restart compose from  ./compose-test-3.yaml
  Compose logs should contain  ./compose-test-3.yaml  *bootstrap*MARKLOGIC_INIT is true, but the server is already initialized. Skipping initialization.*
  Compose logs should contain  ./compose-test-3.yaml  *node2*MARKLOGIC_INIT is true, but the server is already initialized. Skipping initialization.*
  [Teardown]  Delete compose from  ./compose-test-3.yaml

Two node compose with second node uncoupled
  Start compose from  ./compose-test-4.yaml
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for unauthenticated request with  7201  *Unauthorized*
  Host count on port 7102 should be 1
  Host count on port 7202 should be 1
  [Teardown]  Delete compose from  ./compose-test-4.yaml

Two node compose with second node uninitialized
  Start compose from  ./compose-test-5.yaml
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for unauthenticated request with  7201  *This server must now self-install the initial databases and application servers. Click OK to continue.*
  Host count on port 7102 should be 1
  Verify response for authenticated request with  7200  *Forbidden*
  Verify response for authenticated request with  7201  *This server must now self-install the initial databases and application servers. Click OK to continue.*
  Verify response for authenticated request with  7202  *Forbidden*
  [Teardown]  Delete compose from  ./compose-test-5.yaml

Initialized MarkLogic Server with wallet password and realm
  Create container with  -e  MARKLOGIC_INIT=true
  ...                    -e  MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
  ...                    -e  MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
  ...                    -e  MARKLOGIC_WALLET_PASSWORD=test_wallet_pass
  ...                    -e  REALM=public
  Verify response for unauthenticated request with  8000  *Unauthorized*
  Verify response for unauthenticated request with  8001  *Unauthorized*
  Verify response for unauthenticated request with  8002  *Unauthorized*
  Verify response for authenticated request with  8000  *Query Console*
  Verify response for authenticated request with  8001/security-admin.xqy?section=security  *public*
  Verify response for authenticated request with  8002  *Monitoring Dashboard*
  [Teardown]  Delete container