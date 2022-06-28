*** Settings ***
Documentation  These are docker and compose tests.
...            ...
Resource  keywords.resource

# TODO:
# ML config override
# install converters

*** Test Cases ***
Uninitialized MarkLogic container
  Create container with  -e  MARKLOGIC_INIT=false
  Docker log should contain  *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
  Docker log should contain  *MARKLOGIC_INIT is set to false or not defined, not initialzing.*
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
  Docker log should contain  *MARKLOGIC_INIT is true, initialzing.*
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
  Docker log should contain  *MARKLOGIC_INIT is true, initialzing.*
  Verify response for unauthenticated request with  8000  *Unauthorized*
  Verify response for unauthenticated request with  8001  *Unauthorized*
  Verify response for unauthenticated request with  8002  *Unauthorized*
  Verify response for authenticated request with  8000  *Query Console*
  Verify response for authenticated request with  8001/license.xqy  *MarkLogic - Version 9 QA Test License*
  Verify response for authenticated request with  8002  *Monitoring Dashboard*
  [Teardown]  Delete container

Initialized MarkLogic container without credentials
  [Tags]  negative
  Create container with  -e  MARKLOGIC_INIT=true
  Docker log should contain  *MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
  Docker log should contain  *MARKLOGIC_INIT is true, initialzing.*
  Verify response for unauthenticated request with  8000  *Unauthorized*
  Verify response for unauthenticated request with  8001  *Join a Cluster*
  Verify response for unauthenticated request with  8002  *Unauthorized*
  Verify response for authenticated request with  8000  *Unauthorized*
  Verify response for authenticated request with  8001  *Join a Cluster*
  Verify response for authenticated request with  8002  *Unauthorized*
  [Teardown]  Delete container

Initialized MarkLogic container with invalid value for MARKLOGIC_JOIN_CLUSTER
  Create container with  -e  MARKLOGIC_INIT=true
  ...                    -e  MARKLOGIC_ADMIN_USERNAME=${DEFAULT ADMIN USER}
  ...                    -e  MARKLOGIC_ADMIN_PASSWORD=${DEFAULT ADMIN PASS}
  ...                    -e  MARKLOGIC_JOIN_CLUSTER=invalid
  Docker log should contain  *MARKLOGIC_INIT is true, initialzing.*
  Docker log should contain  *ERROR: MARKLOGIC_JOIN_CLUSTER must be true or false.*
  Verify response for unauthenticated request with  8000  *Unauthorized*
  Verify response for unauthenticated request with  8001  *Unauthorized*
  Verify response for unauthenticated request with  8002  *Unauthorized*
  Verify response for authenticated request with  8000  *Query Console*
  Verify response for authenticated request with  8001  *No license key has been entered*
  Verify response for authenticated request with  8002  *Monitoring Dashboard*
  [Teardown]  Delete container

Invalid value for INIT
  Create failing container with  -e  MARKLOGIC_INIT=invalid
  Docker log should contain  *ERROR: MARKLOGIC_INIT must be true or false.*
  [Teardown]  Delete container

Single node compose example
  Start compose from  ./docker-compose/marklogic-centos.yaml
  Verify response for unauthenticated request with  8000  *Unauthorized*
  Verify response for unauthenticated request with  8001  *Unauthorized*
  Verify response for unauthenticated request with  8002  *Unauthorized*
  Verify response for authenticated request with  8000  *Query Console*
  Verify response for authenticated request with  8001  *No license key has been entered*
  Verify response for authenticated request with  8002  *Monitoring Dashboard*
  Compose logs should contain  ./docker-compose/marklogic-centos.yaml  *Setting timezone to Europe/Prague*
  [Teardown]  Delete compose from  ./docker-compose/marklogic-centos.yaml

Three node compose example
  Start compose from  ./docker-compose/marklogic-cluster-centos.yaml
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
  [Teardown]  Delete compose from  ./docker-compose/marklogic-cluster-centos.yaml

Two node compose with credentials in env and verify restart logic
  Start compose from  ./test/compose-test-3.yaml
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
  Restart compose from  ./test/compose-test-3.yaml
  Compose logs should contain  ./test/compose-test-3.yaml  *bootstrap*Setting timezone to America/Los_Angeles*
  Compose logs should contain  ./test/compose-test-3.yaml  *bootstrap*Using ENV for credentials.*
  Compose logs should contain  ./test/compose-test-3.yaml  *bootstrap*MARKLOGIC_INIT is true, initialzing.*
  Compose logs should contain  ./test/compose-test-3.yaml  *bootstrap*MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
  Compose logs should contain  ./test/compose-test-3.yaml  *node2*Setting timezone to America/Los_Angeles*
  Compose logs should contain  ./test/compose-test-3.yaml  *node2*Using ENV for credentials.*
  Compose logs should contain  ./test/compose-test-3.yaml  *node2*MARKLOGIC_INIT is true, initialzing.*
  Compose logs should contain  ./test/compose-test-3.yaml  *node2*MARKLOGIC_JOIN_CLUSTER is false or not defined, not joining cluster.*
  Restart compose from  ./test/compose-test-3.yaml
  Compose logs should contain  ./test/compose-test-3.yaml  *bootstrap*MARKLOGIC_INIT is already initialized.*
  Compose logs should contain  ./test/compose-test-3.yaml  *node2*MARKLOGIC_INIT is already initialized.*
  # [Teardown]  Delete compose from  ./test/compose-test-3.yaml

Two node compose with second node uncoupled
  Start compose from  ./test/compose-test-4.yaml
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for unauthenticated request with  7201  *Unauthorized*
  Host count on port 7102 should be 1
  Host count on port 7202 should be 1
  [Teardown]  Delete compose from  ./test/compose-test-4.yaml

Two node compose with second node uninitialized
  Start compose from  ./test/compose-test-5.yaml
  Verify response for unauthenticated request with  7101  *Unauthorized*
  Verify response for unauthenticated request with  7201  *This server must now self-install the initial databases and application servers. Click OK to continue.*
  Host count on port 7102 should be 1
  Verify response for authenticated request with  7200  *Forbidden*
  Verify response for authenticated request with  7201  *This server must now self-install the initial databases and application servers. Click OK to continue.*
  Verify response for authenticated request with  7202  *Forbidden*
  [Teardown]  Delete compose from  ./test/compose-test-5.yaml
