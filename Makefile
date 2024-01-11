version?=internal
package?=MarkLogic.rpm
REPONAME=local-dev
docker_registry?=ml-docker-db-dev-tierpoint.bed-artifactory.bedford.progress.com
repoDir=marklogic
docker_build_options=--compress
test_image?=${docker_registry}/${repoDir}/marklogic-server-centos:${version}
build_branch?=local

#***************************************************************************
# build centos docker images
#***************************************************************************
build-centos:
	cd src/; docker build ${docker_build_options} -t "${REPONAME}/marklogic-deps-centos:${version}" -f ../dockerFiles/marklogic-deps-centos:base .
	cd src/; docker build ${docker_build_options} -t "${REPONAME}/marklogic-server-centos:${version}" --build-arg BASE_IMAGE=${REPONAME}/marklogic-deps-centos:${version} --build-arg ML_RPM=${package} --build-arg ML_USER=marklogic_user --build-arg ML_VERSION=${version} --build-arg ML_CONVERTERS=${converters} --build-arg BUILD_BRANCH=${build_branch} -f ../dockerFiles/marklogic-server-centos:base .

#***************************************************************************
# build ubi docker images
#***************************************************************************
build-ubi:
	cd src/; docker build ${docker_build_options} -t "${REPONAME}/marklogic-deps-ubi:${version}" -f ../dockerFiles/marklogic-deps-ubi:base .
	cd src/; docker build ${docker_build_options} -t "${REPONAME}/marklogic-server-ubi:${version}" --build-arg BASE_IMAGE=${REPONAME}/marklogic-deps-ubi:${version} --build-arg ML_RPM=${package} --build-arg ML_USER=marklogic_user --build-arg ML_VERSION=${version} --build-arg ML_CONVERTERS=${converters} --build-arg BUILD_BRANCH=${build_branch} -f ../dockerFiles/marklogic-server-ubi:base .

#***************************************************************************
# build ubi rootless docker images
#***************************************************************************
build-ubi-rootless:
	cd src/; docker build ${docker_build_options} -t "${REPONAME}/marklogic-deps-ubi:${version}" -f ../dockerFiles/marklogic-deps-ubi:base .
	cd src/; docker build ${docker_build_options} -t "${REPONAME}/marklogic-server-ubi-rootless:${version}" --build-arg BASE_IMAGE=${REPONAME}/marklogic-deps-ubi:${version} --build-arg ML_RPM=${package} --build-arg ML_USER=marklogic_user --build-arg ML_VERSION=${version} --build-arg ML_CONVERTERS=${converters} --build-arg BUILD_BRANCH=${build_branch} -f ../dockerFiles/marklogic-server-ubi-rootless:base .

#***************************************************************************
# strcture test docker images
#***************************************************************************
structure-test:
	container-structure-test test --config ./test/structure-test.yaml --image TEST_IMAGE:${test_image} \
		$(if $(Jenkins), --output junit | tee container-structure-test.xml,)

#***************************************************************************
# docker image tests
#***************************************************************************
docker-tests: 
	cd test; python3 -m venv python_env
	cd test; source ./python_env/bin/activate; pip3 install -r requirements.txt; robot -x docker-tests.xml --outputdir test_results --variable TEST_IMAGE:${test_image} --variable MARKLOGIC_VERSION:${version} --variable BUILD_BRANCH:${build_branch} --maxerrorlines 9999 ./docker-tests.robot; deactivate
	rm -r test/python_env/
	
#***************************************************************************
# run all tests
#***************************************************************************
.PHONY: test
test: structure-test docker-tests
	
#***************************************************************************
# push docker images to mlregistry.marklogic.com
#***************************************************************************
push-mlregistry:
	docker tag ${REPONAME}/marklogic-server-centos:${version} ${docker_registry}/${repoDir}/marklogic-server-centos:${version}
	docker push ${docker_registry}/${repoDir}/marklogic-server-centos:${version}

#***************************************************************************
# run lint checker on Dockerfiles, print linting issues but do not fail the build
#***************************************************************************
lint:
	docker run --rm -v "${PWD}:/mnt" koalaman/shellcheck:stable src/scripts/*.sh $(if $(Jenkins), > start-scripts-lint.txt,)
	docker run --rm -i -v "${PWD}/hadolint.yaml":/.config/hadolint.yaml ghcr.io/hadolint/hadolint < dockerFiles/marklogic-deps-centos:base $(if $(Jenkins), > marklogic-deps-centos-base-lint.txt,)
	docker run --rm -i -v "${PWD}/hadolint.yaml":/.config/hadolint.yaml ghcr.io/hadolint/hadolint < dockerFiles/marklogic-server-centos:base $(if $(Jenkins), > marklogic-server-centos-base-lint.txt,)
	docker run --rm -i -v "${PWD}/hadolint.yaml":/.config/hadolint.yaml ghcr.io/hadolint/hadolint < dockerFiles/marklogic-server-ubi:base $(if $(Jenkins), >> marklogic-server-centos-base-lint.txt,)
	docker run --rm -i -v "${PWD}/hadolint.yaml":/.config/hadolint.yaml ghcr.io/hadolint/hadolint < dockerFiles/marklogic-server-ubi-rootless:base $(if $(Jenkins), >> marklogic-server-centos-base-lint.txt,)

#***************************************************************************
# security scan docker images
#***************************************************************************
scan:
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock anchore/grype:latest TEST_IMAGE:${test_image} $(if $(Jenkins), > scan-server-image.txt,)
	
#***************************************************************************
# remove junk
#***************************************************************************
clean:
	rm -f *.log
	rm -f *.rpm