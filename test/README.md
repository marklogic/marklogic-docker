# Docker Tests

There are two types of tests: Docker structure tests and Docker image tests. Both are started by the pipeline.

## Docker Structure Tests
We use [container-structure-test](https://github.com/GoogleContainerTools/container-structure-testhttps:/) to validate the structure of our Docker images. Configuration file structure-test.yaml defines the test cases for validation of image metadata, exposed ports, and essential files.

Here is an example command to run the test:

`container-structure-test test --config ./structure-test.yaml --image ml-docker-dev.marklogic.com/marklogic/marklogic-server-centos:10.0-8.1-centos-1.0.0-ea2`


## Docker Image Tests
Test cases for Docker image tests are defined in docker-test-cases.json. Test cases validate running containers with either authenticated or unauthenticated user.
Each test defines a port and a string to match in the response. Pipeline iterates through the test cases and generates a junit report.
The driver is defined in DockerRunTests().
