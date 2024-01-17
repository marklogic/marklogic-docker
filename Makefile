version?=internal
package?=MarkLogic.rpm
repo_dir=marklogic
docker_build_options=--compress
build_branch?=local
docker_image_type?=ubi
current_image?=${repo_dir}/marklogic-server-${docker_image_type}:${version}

#***************************************************************************
# build docker image
#***************************************************************************
build:
#ubi-rootless uses the same dependencies as ubi image
ifeq ($(docker_image_type),ubi-rootless)
	cp dockerFiles/marklogic-deps-ubi\:base dockerFiles/marklogic-deps-ubi-rootless\:base
endif
	cd src/; docker build ${docker_build_options} -t "${repo_dir}/marklogic-deps-${docker_image_type}:${version}" -f ../dockerFiles/marklogic-deps-${docker_image_type}:base .
	cd src/; docker build ${docker_build_options} -t "${repo_dir}/marklogic-server-${docker_image_type}:${version}" --build-arg BASE_IMAGE=${repo_dir}/marklogic-deps-${docker_image_type}:${version} --build-arg ML_RPM=${package} --build-arg ML_USER=marklogic_user --build-arg ML_VERSION=${version} --build-arg ML_CONVERTERS=${converters} --build-arg BUILD_BRANCH=${build_branch} -f ../dockerFiles/marklogic-server-${docker_image_type}:base .
	rm -f dockerFiles/marklogic-deps-ubi-rootless\:base
#***************************************************************************
# strcture test docker images
#***************************************************************************
structure-test:
	container-structure-test test --config ./test/structure-test.yaml --image ${current_image} \
		$(if $(Jenkins), --output junit | tee container-structure-test.xml,)

#***************************************************************************
# docker image tests
#***************************************************************************
docker-tests: 
	cd test; python3 -m venv python_env
	cd test; source ./python_env/bin/activate; pip3 install -r requirements.txt; robot -x docker-tests.xml --outputdir test_results --variable TEST_IMAGE:${current_image} --variable MARKLOGIC_VERSION:${version} --variable BUILD_BRANCH:${build_branch} --maxerrorlines 9999 ./docker-tests.robot; deactivate
	rm -r test/python_env/
	
#***************************************************************************
# run all tests
#***************************************************************************
.PHONY: test
test: structure-test docker-tests

#***************************************************************************
# run lint checker on shell scripts and Dockerfiles, print linting issues but do not fail the build
#***************************************************************************

lint:
	docker run --rm -v "${PWD}:/mnt" koalaman/shellcheck:stable src/scripts/*.sh $(if $(Jenkins), > start-scripts-lint.txt,)

	@for dockerFile in $(shell ls ./dockerFiles/); do\
	    echo "Lint results for $${dockerFile}" $(if $(Jenkins), >> dockerfile-lint.txt,) ; \
		docker run --rm -i -v "${PWD}/hadolint.yaml":/.config/hadolint.yaml ghcr.io/hadolint/hadolint < dockerFiles/$${dockerFile} $(if $(Jenkins), >> dockerfile-lint.txt,);\
		echo $(if $(Jenkins), >> dockerfile-lint.txt,) ;\
	done

#***************************************************************************
# security scan docker images
#***************************************************************************
scan:
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock anchore/grype:latest ${current_image} $(if $(Jenkins), > scan-server-image.txt,)
	
#***************************************************************************
# remove junk
#***************************************************************************
clean:
	rm -f *.log
	rm -f *.rpm
