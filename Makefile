dockerTag?=internal
package?=MarkLogic.rpm
repo_dir=marklogic
docker_build_options=--compress --platform linux/amd64
build_branch?=local
docker_image_type?=ubi
upgrade_docker_image_type?=ubi
upgrade_image?=${repo_dir}/marklogic-server-${upgrade_docker_image_type}:${dockerTag}
current_image?=${repo_dir}/marklogic-server-${docker_image_type}:${dockerTag}
open_scap_version?=0.1.74

#***************************************************************************
# build docker image
#***************************************************************************
build:
# NOTICE file need to be in the build context to be included in the built image
	cp NOTICE.txt src/NOTICE.txt

# rootless images use the same dependencies as ubi image so we copy the file
ifeq ($(docker_image_type),ubi-rootless)
	cp dockerFiles/marklogic-deps-ubi\:base dockerFiles/marklogic-deps-ubi-rootless\:base
endif
ifeq ($(docker_image_type),ubi-rootless-hardened)
	cp dockerFiles/marklogic-deps-ubi\:base dockerFiles/marklogic-deps-ubi-rootless-hardened\:base
endif

# retrieve and copy open scap hardening script
ifeq ($(docker_image_type),ubi-rootless-hardened)
	[ -f scap-security-guide-${open_scap_version}.zip ] || curl -Lo scap-security-guide-${open_scap_version}.zip https://github.com/ComplianceAsCode/content/releases/download/v${open_scap_version}/scap-security-guide-${open_scap_version}.zip
	unzip -p scap-security-guide-${open_scap_version}.zip scap-security-guide-${open_scap_version}/bash/rhel8-script-cis.sh > src/rhel8-script-cis.sh
endif

# build the image
	cd src/; docker build ${docker_build_options} -t "${repo_dir}/marklogic-deps-${docker_image_type}:${dockerTag}" -f ../dockerFiles/marklogic-deps-${docker_image_type}:base .
	cd src/; docker build ${docker_build_options} -t "${repo_dir}/marklogic-server-${docker_image_type}:${dockerTag}" --build-arg BASE_IMAGE=${repo_dir}/marklogic-deps-${docker_image_type}:${dockerTag} --build-arg ML_RPM=${package} --build-arg ML_USER=marklogic_user --build-arg ML_DOCKER_VERSION=${dockerVersion} --build-arg ML_VERSION=${marklogicVersion} --build-arg ML_CONVERTERS=${converters} --build-arg BUILD_BRANCH=${build_branch} -f ../dockerFiles/marklogic-server-${docker_image_type}:base .
	rm -f dockerFiles/marklogic-deps-ubi-rootless\:base dockerFiles/marklogic-deps-ubi-rootless-hardened\:base

#***************************************************************************
# strcture test docker images
#***************************************************************************
structure-test:
ifeq ($(findstring rootless,$(docker_image_type)),rootless)
	@echo type is ${docker_image_type}
	sed -i -e 's^DOCKER_PID_PLACEHOLDER^/home/marklogic_user/MarkLogic.pid^g' ./test/structure-test.yaml
else
	@echo type is ${docker_image_type}
	sed -i -e 's^DOCKER_PID_PLACEHOLDER^/var/run/MarkLogic.pid^g' ./test/structure-test.yaml
endif
	sed -i -e 's^ML_VERSION_PLACEHOLDER^${marklogicVersion}^g' ./test/structure-test.yaml
	sed -i -e 's^ML_DOCKER_VERSION_PLACEHOLDER^${dockerVersion}^g' ./test/structure-test.yaml
	sed -i -e 's^BRANCH_PLACEHOLDER^${build_branch}^g' ./test/structure-test.yaml
	container-structure-test test --config ./test/structure-test.yaml --image ${current_image} \
		$(if $(Jenkins), --output junit | tee container-structure-test.xml,)

#***************************************************************************
# docker image tests
#***************************************************************************
docker-tests: 
	cd test; \
	python3 -m venv python_env; \
	source ./python_env/bin/activate; \
	pip3 install -r requirements.txt; \
	robot -x docker-tests.xml --outputdir test_results --randomize all --variable TEST_IMAGE:${current_image} --variable UPGRADE_TEST_IMAGE:${upgrade_image} --variable MARKLOGIC_VERSION:${marklogicVersion} --variable BUILD_BRANCH:${build_branch} --variable MARKLOGIC_DOCKER_VERSION:${dockerVersion} --variable IMAGE_TYPE:${docker_image_type} --maxerrorlines 9999 ./docker-tests.robot; \
	deactivate; \
	rm -rf python_env
	
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
# security scan docker images
#***************************************************************************
scap-scan:
	mkdir -p scap
	[ -f scap-security-guide-${open_scap_version}.zip ] || curl -Lo scap-security-guide-${open_scap_version}.zip https://github.com/ComplianceAsCode/content/releases/download/v${open_scap_version}/scap-security-guide-${open_scap_version}.zip
	unzip -p scap-security-guide-${open_scap_version}.zip scap-security-guide-${open_scap_version}/ssg-rhel8-ds.xml > scap/ssg-rhel8-ds.xml
	docker run -itd --name scap-scan -v $(PWD)/scap:/scap ${current_image}
	docker exec -u root scap-scan /bin/bash -c "microdnf install -y openscap-scanner"
	docker exec -u root scap-scan /bin/bash -c "oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis --results /scap/scap_scan_results.xml --report /scap/scap_scan_report.html /scap/ssg-rhel8-ds.xml" || true
	docker rm -f scap-scan

#***************************************************************************
# remove junk
#***************************************************************************
clean:
	rm -f *.log
	rm -f *.rpm
