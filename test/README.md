# Docker Tests

There are two types of tests: Docker structure tests and Docker image tests.

## Docker Structure Tests
We use [container-structure-test](https://github.com/GoogleContainerTools/container-structure-test) to validate the structure of our Docker images. Configuration file structure-test.yaml defines the test cases for validation of image metadata, exposed ports, and essential files.

The tests are run through the a makefile command runnable using:

`make structure-test`

If you'd like to change the image being tested change the variables in the makefile and if you want to change the tests themselves refer to the structure-test.yaml file in this folder.

## Docker Image Tests
Docker image tests are implemented with Robot framework. The framework requires Python 3.6+ and pip. Framework requirements are listed in requirements file and can be installed with the following commands:
`python3 -m venv python_env`
`source ./python_env/bin/activate`
`pip3 install -r requirements.txt`

After running the tests, you can deactivate the environment and delete it if needed.
`deactivate`
`rm -r ./python_env/`

For additional installation instruction see https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#installation-instructions

In order to run Docker tests, you need to have MarkLogic Docker image available in your environment. The image can be passed as a parameter or set with DOCKER_TEST_IMAGE environment variable.

In order to execute a single test case with a published Docker image, use
`robot --variable TEST_IMAGE:progressofficial/marklogic-db --test "Initialized MarkLogic container" ./docker-tests.robot`

In order to run all tests you can use make from root folder with
`make docker-tests test_image=progressofficial/marklogic-db`

or by running Robot in test directly with 
`robot ./docker-tests.robot`

*Note*
QA_LICENSE_KEY environment variable needs to be set to a valid license key for license test to pass.
If UBI rootless image is used, specify image type for individual tests:
`robot --variable TEST_IMAGE:marklogic/marklogic-server-ubi-rootless:internal --variable IMAGE_TYPE:ubi-rootless --test 'Initialized MarkLogic container with config overrides' docker-tests.robot`

For a quick start guide for Robot framework see https://robotframework.org/#getting-started
Full user guide is available at https://robotframework.org/robotframework/#user-guide

The following vscode extensions are recommended for code completion and test execution:
  https://marketplace.visualstudio.com/items?itemName=robocorp.robocorp-code
  https://marketplace.visualstudio.com/items?itemName=robocorp.robotframework-lsp

