# Docker Tests

There are two types of tests: Docker structure tests and Docker image tests. Both are started by the pipeline.

## Docker Structure Tests
We use [container-structure-test](https://github.com/GoogleContainerTools/container-structure-test) to validate the structure of our Docker images. Configuration file structure-test.yaml defines the test cases for validation of image metadata, exposed ports, and essential files.

The tests are run through the a makefile command runnable using:

`make structure-test`

If you'd like to change the image being tested change the variables in the makefile and if you want to change the tests themselves refer to the structure-test.yaml file in this folder.
## Docker Image Tests
Test cases for Docker image tests are defined in docker-test-cases.json. Test cases validate running containers with either authenticated or unauthenticated user.
Each test defines a port and a string to match in the response. Pipeline iterates through the test cases and generates a junit report.
The driver is defined in DockerRunTests().
