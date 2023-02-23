version?=10-internal
package?=MarkLogic.rpm
REPONAME=marklogic-centos
repoDir=marklogic
docker_build_options=--compress
test_image?=ml-docker-dev.marklogic.com/${repoDir}/marklogic-server-centos:${version}
build_branch?=local

#***************************************************************************
# build docker images
#***************************************************************************
build:
	cd src/centos/; docker build ${docker_build_options} -t "${REPONAME}/marklogic-deps-centos:${version}" -f ../../dockerFiles/marklogic-deps-centos:base .
	cd src/centos/; docker build ${docker_build_options} -t "${REPONAME}/marklogic-server-centos:${version}" --build-arg BASE_IMAGE=${REPONAME}/marklogic-deps-centos:${version} --build-arg ML_RPM=${package} --build-arg ML_USER=marklogic_user --build-arg ML_VERSION=${version} --build-arg ML_CONVERTERS=${converters} --build-arg BUILD_BRANCH=${build_branch} -f ../../dockerFiles/marklogic-server-centos:base .

#***************************************************************************
# strcture test docker images
#***************************************************************************
structure-test:
	container-structure-test test --config ./test/structure-test.yaml --image ${REPONAME}/marklogic-server-centos:${version} \
		$(if $(Jenkins), --output junit | tee container-structure-test.xml,)

#***************************************************************************
# docker image tests
#***************************************************************************
docker-tests: 
	cd test; robot -x docker-tests.xml --outputdir test_results --variable TEST_IMAGE:${test_image} --variable MARKLOGIC_VERSION:${version} --variable BUILD_BRANCH:${build_branch} --maxerrorlines 9999 ./docker-tests.robot

#***************************************************************************
# run all tests
#***************************************************************************
.PHONY: test
test: structure-test docker-tests
	
#***************************************************************************
# push docker images to mlregistry.marklogic.com
#***************************************************************************
push-mlregistry:
	docker tag ${REPONAME}/marklogic-server-centos:${version} ml-docker-dev.marklogic.com/${repoDir}/marklogic-server-centos:${version}
	docker push ml-docker-dev.marklogic.com/${repoDir}/marklogic-server-centos:${version}

#***************************************************************************
# run lint checker on Dockerfiles, print linting issues but do not fail the build
#***************************************************************************
lint:
	docker run --rm -v "${PWD}:/mnt" koalaman/shellcheck:stable src/centos/scripts/start-marklogic.sh $(if $(Jenkins), > start-marklogic-lint.txt,)
	docker run --rm -i -v "${PWD}/hadolint.yaml":/.config/hadolint.yaml ghcr.io/hadolint/hadolint < dockerFiles/marklogic-deps-centos:base $(if $(Jenkins), > marklogic-deps-centos-base-lint.txt,)
	docker run --rm -i -v "${PWD}/hadolint.yaml":/.config/hadolint.yaml ghcr.io/hadolint/hadolint < dockerFiles/marklogic-server-centos:base $(if $(Jenkins), > marklogic-server-centos-base-lint.txt,)

#***************************************************************************
# security scan docker images
#***************************************************************************
scan:
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock anchore/grype:latest ${REPONAME}/marklogic-server-centos:${version} $(if $(Jenkins), > scan-server-image.txt,)
	
#***************************************************************************
# remove junk
#***************************************************************************
clean:
	rm -f *.log
	rm -f *.rpm