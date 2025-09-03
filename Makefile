# Copyright © 2018-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
ifeq ($(docker_image_type),ubi9)
	cp dockerFiles/marklogic-server-ubi\:base dockerFiles/marklogic-server-ubi9\:base
endif
ifeq ($(findstring rootless,$(docker_image_type)),rootless)
	cp dockerFiles/marklogic-deps-ubi\:base dockerFiles/marklogic-deps-ubi-rootless\:base
	cp dockerFiles/marklogic-deps-ubi9\:base dockerFiles/marklogic-deps-ubi9-rootless\:base
	cp dockerFiles/marklogic-server-ubi-rootless\:base dockerFiles/marklogic-server-ubi9-rootless\:base
endif

# retrieve and copy open scap hardening script
ifeq ($(findstring rootless,$(docker_image_type)),rootless)
	[ -f scap-security-guide-${open_scap_version}.zip ] || curl -Lo scap-security-guide-${open_scap_version}.zip https://github.com/ComplianceAsCode/content/releases/download/v${open_scap_version}/scap-security-guide-${open_scap_version}.zip
#UBI9 needs a different version of the remediation script
ifeq ($(findstring ubi9,$(docker_image_type)),ubi9)
	unzip -p scap-security-guide-${open_scap_version}.zip scap-security-guide-${open_scap_version}/bash/rhel9-script-cis.sh > src/rhel-script-cis.sh
else
	unzip -p scap-security-guide-${open_scap_version}.zip scap-security-guide-${open_scap_version}/bash/rhel8-script-cis.sh > src/rhel-script-cis.sh
endif
endif


# build the image
	cd src/; docker build ${docker_build_options} -t "${repo_dir}/marklogic-deps-${docker_image_type}:${dockerTag}" --build-arg ML_VERSION=${marklogicVersion} -f ../dockerFiles/marklogic-deps-${docker_image_type}:base .
	cd src/; docker build ${docker_build_options} -t "${repo_dir}/marklogic-server-${docker_image_type}:${dockerTag}" --build-arg BASE_IMAGE=${repo_dir}/marklogic-deps-${docker_image_type}:${dockerTag} --build-arg ML_RPM=${package} --build-arg ML_USER=marklogic_user --build-arg ML_DOCKER_VERSION=${dockerVersion} --build-arg ML_VERSION=${marklogicVersion} --build-arg ML_CONVERTERS=${converters} --build-arg BUILD_BRANCH=${build_branch} --build-arg ML_DOCKER_TYPE=${docker_image_type} -f ../dockerFiles/marklogic-server-${docker_image_type}:base .

# remove temporary files
	rm -f dockerFiles/marklogic-deps-ubi-rootless\:base dockerFiles/marklogic-deps-ubi9-rootless\:base dockerFiles/marklogic-server-ubi9-rootless\:base dockerFiles/marklogic-server-ubi9\:base src/NOTICE.txt src/rhel-script-cis.sh

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
.PHONY: scan
scan:
ifeq ($(Jenkins),true)
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v ${PWD}/scan:/scan anchore/grype:latest --output json --file scan/report-${docker_image_type}.json ${current_image}
	sudo chown -R builder.ml-eng scan
	echo -e "Grype scan summary\n------------------" > scan/report-${docker_image_type}.txt
	jq '.matches[].vulnerability.severity' scan/report-${docker_image_type}.json | sort | uniq -c >> scan/report-${docker_image_type}.txt
	echo -e "\nGrype vulnerability list sorted by severity.\n" >> scan/report-${docker_image_type}.txt
	echo -e "PACKAGE\tVERSION\tCVE\tSEVERITY" >> scan/report-${docker_image_type}.tmp
# generate txt file
	jq -r '[(.matches[] | [.artifact.name, .artifact.version, .vulnerability.id, .vulnerability.severity])] | .[] | @tsv' scan/report-${docker_image_type}.json | sort -k4 >> scan/report-${docker_image_type}.tmp
	cat scan/report-${docker_image_type}.tmp | column -t >> scan/report-${docker_image_type}.txt
	rm scan/report-${docker_image_type}.tmp
# generate csv file
	jq -r '["ID", "Severity", "CVSS Base Score", "Link", "Package"], (.matches[] | [.vulnerability.id, .vulnerability.severity, (.vulnerability.cvss[0].metrics.baseScore // "N/A"), (.relatedVulnerabilities[]?.dataSource // .vulnerability.dataSource), .artifact.name]) | @csv' scan/report-${docker_image_type}.json > scan/report-${docker_image_type}.csv
else
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock anchore/grype:latest ${current_image}
endif
#***************************************************************************
# security scan docker images
#***************************************************************************
scap-scan:
	mkdir -p scap
	[ -f scap-security-guide-${open_scap_version}.zip ] || curl -Lo scap-security-guide-${open_scap_version}.zip https://github.com/ComplianceAsCode/content/releases/download/v${open_scap_version}/scap-security-guide-${open_scap_version}.zip
#UBI9 needs a different version of the evaluation profile
ifeq ($(findstring ubi9,$(current_image)),ubi9)
	unzip -p scap-security-guide-${open_scap_version}.zip scap-security-guide-${open_scap_version}/ssg-rhel9-ds.xml > scap/ssg-rhel-ds.xml
else
	unzip -p scap-security-guide-${open_scap_version}.zip scap-security-guide-${open_scap_version}/ssg-rhel8-ds.xml > scap/ssg-rhel-ds.xml
endif
	docker run -itd --name scap-scan -v $(PWD)/scap:/scap ${current_image}
	docker exec -u root scap-scan /bin/bash -c "microdnf update -y; microdnf install -y openscap-scanner"
	# ensure the file is owned by root in order to avoid permission issues
	docker exec -u root scap-scan /bin/bash -c "chown root:root /scap/ssg-rhel-ds.xml"
	docker exec -u root scap-scan /bin/bash -c "oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis --results /scap/scap_scan_results.xml --report /scap/scap_scan_report.html /scap/ssg-rhel-ds.xml > /scap/command-output.txt 2>&1" || true
	docker exec -u root scap-scan /bin/bash -c "rm -f /scap/ssg-rhel-ds.xml"
	docker rm -f scap-scan

#***************************************************************************
# remove junk
#***************************************************************************
clean:
	rm -f *.log
	rm -f *.rpm
