# Docker Tests

There are two types of tests: Docker structure tests and Docker image tests.

## Docker Structure Tests
We use [container-structure-test](https://github.com/GoogleContainerTools/container-structure-test) to validate the structure of our Docker images. Configuration file structure-test.yaml defines the test cases for validation of image metadata, exposed ports, and essential files.

The tests are run through the a makefile command runnable using:

`make structure-test`

If you'd like to change the image being tested change the variables in the makefile and if you want to change the tests themselves refer to the structure-test.yaml file in this folder.

## Docker Image Tests
Docker image tests are implemented with Robot framework. The framework requires Python 3.6+ and pip. Framework requirements are listed in requirements file and can be installed with
`pip install -r requirements.txt`

For additional installation instruction see https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#installation-instructions

In order to run all tests you can use make with
`make docker-tests test_image={docker image label}`
or by running Robot directly
`cd test; robot ./docker-tests.robot`

QA_LICENSE_KEY environment variable needs to be set to a valid license key for license test to pass.

For a quick start guide for Robot framework see https://robotframework.org/#getting-started
Full user guide is available at https://robotframework.org/robotframework/#user-guide

The following vscode extensions are recommended for code completion and test execution:
  https://marketplace.visualstudio.com/items?itemName=robocorp.robocorp-code
  https://marketplace.visualstudio.com/items?itemName=robocorp.robotframework-lsp

