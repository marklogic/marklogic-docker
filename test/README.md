We use [container-structure-test](https://github.com/GoogleContainerTools/container-structure-testhttps:/) to validate the structure of our Docker images. Configuration file structure-test.yml defines the test cases for validation of image metadata, exposed ports, and essential files.

Here is an example command to run the test:

`container-structure-test test --config ./structure-test.yml --image ml-docker-dev.marklogic.com/marklogic/marklogic-server-centos:10.0-8.1-centos-1.0.0-ea2`
