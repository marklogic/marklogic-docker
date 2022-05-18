version?=10-internal
package?=MarkLogic.rpm
REPONAME=marklogic-centos
repoDir="marklogic"
docker_build_options=--compress
container_test_tool=${PWD}/../../bin/container-structure-test

#***************************************************************************
# build docker images
#***************************************************************************
build:
	docker build ${docker_build_options} -t "${REPONAME}/marklogic-deps-centos:${version}" -f ../../dockerFiles/marklogic-deps-centos:base .
	docker build ${docker_build_options} -t "${REPONAME}/marklogic-server-centos:${version}" --build-arg BASE_IMAGE=${REPONAME}/marklogic-deps-centos:${version} --build-arg ML_RPM=${package} --build-arg ML_USER=marklogic_user --build-arg ML_VERSION=${version} --build-arg ML_CONVERTERS=${converters} -f ../../dockerFiles/marklogic-server-centos:base .

#***************************************************************************
# run lint checker on Dockerfiles ** TBD **
#***************************************************************************
lint:
	docker run --rm --privileged -v ${PWD}:/root/ projectatomic/dockerfile-lint dockerfile_lint -p -f marklogic-server-centos:${version}

#***************************************************************************
# test docker images ** TBD **
#***************************************************************************
test:
	${container_test_tool} test --image ${REPONAME}/marklogic-server-centos:${version} --config "test/test-marklogic-server-centos:${version}.yaml"

#***************************************************************************
# push docker images to mlregistry.marklogic.com
#***************************************************************************
push-mlregistry:

	docker tag ${REPONAME}/marklogic-server-centos:${version} ml-docker-dev.marklogic.com/${repoDir}/marklogic-server-centos:${version}
	docker push ml-docker-dev.marklogic.com/${repoDir}/marklogic-server-centos:${version}

#***************************************************************************
# security scan docker images ** TBD **
#***************************************************************************
scan:
	#curl -s https://ci-tools.anchore.io/inline_scan-v0.3.3 | bash -s -- -p -r  ${REPONAME}/marklogic-server-centos:${version}
	docker build -t "${REPONAME}/marklogic-server-centos:${version}-security-scan" -f marklogic-server-centos:${version}-security-scan .
	docker run --privileged  -d --name security-scan-${version} -it ${REPONAME}/marklogic-server-centos:${version}-security-scan
	docker exec security-scan-${version} sudo rkhunter --update || true
	docker exec --privileged security-scan-${version} sudo rkhunter -c -sk -q || true
	docker exec security-scan-${version} sudo cat /var/log/rkhunter/rkhunter.log > rkhunter${version}.log
	docker exec --privileged security-scan-${version} sudo lynis -c --quick --pentest --auditor "marklogic" audit system > lynis${version}.log
	docker exec --privileged security-scan-${version} sudo freshclam
	docker exec --privileged security-scan-${version} sudo clamscan -r / -i --exclude-dir=^/sys --exclude-dir=^/dev --exclude-dir=^/proc > clamscan${version}.log
	docker kill security-scan-${version}
	docker rm security-scan-${version}

#***************************************************************************
# remove junk
#***************************************************************************
clean:
	rm -f *.log
	rm -f *.rpm