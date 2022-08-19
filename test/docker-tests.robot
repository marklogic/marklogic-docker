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
  Docker log should contain  *ML_ADMIN_USERNAME and ML_ADMIN_PASSWORD must be set.*
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
  Start compose from  ../docker-compose/marklogic-centos.yaml
  Verify response for unauthenticated request with  8000  *Unauthorized*
  Verify response for unauthenticated request with  8001  *Unauthorized*
  Verify response for unauthenticated request with  8002  *Unauthorized*
  Verify response for authenticated request with  8000  *Query Console*
  Verify response for authenticated request with  8001  *No license key has been entered*
  Verify response for authenticated request with  8002  *Monitoring Dashboard*
  Compose logs should contain  ../docker-compose/marklogic-centos.yaml  *TZ is defined, setting timezone to Europe/Prague.*
  [Teardown]  Delete compose from  ../docker-compose/marklogic-centos.yaml

Three node compose example
  Start compose from  ../docker-compose/marklogic-cluster-centos.yaml
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
  [Teardown]  Delete compose from  ../docker-compose/marklogic-cluster-centos.yaml

Two node compose example with node joining Default group
  Start compose from  ./compose-test-6.yaml
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
  Host on 7202 should be part of group Default
  [Teardown]  Delete compose from  ./compose-test-6.yaml

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
  
