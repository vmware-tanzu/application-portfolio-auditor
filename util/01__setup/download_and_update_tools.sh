#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Download and containerize all tools instrumented by "Application Portfolio Auditor" and several supportive frameworks and libraries.
#
# The container images built by this script are only valid for systems having the same processor architecture (e.g. x86/ARM/x64).
##############################################################################################################

# ----- Please adjust

# Set to true to get update all local vulnerability databases updated
UPDATE_VULN_DBS=false

# ------ Do not modify
[[ "$DEBUG" == "true" ]] && set -x
set -eu
SCRIPT_PATH="$(
	cd -- "$(dirname "$0")" >/dev/null 2>&1
	pwd -P
)"
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
HOME_DIR="${SCRIPT_DIR}/../.."
export DIST_DIR="${HOME_DIR}/dist"

# shellcheck source=/dev/null
source "${HOME_DIR}/_versions.sh"

# Determining platform architecture for the build
ARCH="$(uname -m)"
export CONTAINER_ARCH="$([[ "${ARCH}" == "arm64" ]] && echo "arm64" || echo "amd64")"
export CONTAINER_PLATFORM="linux/${CONTAINER_ARCH}"

if [[ "${CONTAINER_ARCH}" == "arm64" ]]; then
	export DOTNET_RUNTIME="${IMG_DOTNET_RUNTIME}-${CONTAINER_ARCH}v8"
else
	export DOTNET_RUNTIME="${IMG_DOTNET_RUNTIME}-${CONTAINER_ARCH}"
fi

# shellcheck disable=SC1091
source "${CURRENT_DIR}/_shared_functions.sh"

function check_container_engine() {
	if [[ -z "$(command -v ${CONTAINER_ENGINE})" ]]; then
		if [[ "${CONTAINER_ENGINE}" == "docker" ]]; then
			if [[ "${IS_MAC}" == "true" ]]; then
				echo_console_error "'docker' is not available. Please install it and start the docker daemon.
		[MacOS] Install docker (UI required) with brew and start its daemon
			$ brew install docker
			$ open /Applications/Docker.app"
			else
				echo_console_error "'docker' is not available. Please install it and start the docker daemon.
		[CentoOS/RHEL/Fedora] Install docker and start its daemon
			$ sudo yum install -y yum-utils device-mapper-persistent-data lvm2
			$ sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
			$ sudo yum -y install docker-ce docker-ce-cli --nobest
			$ sudo groupadd docker
			$ sudo usermod -aG docker \${USER}
			$ sudo mkdir -p /etc/systemd/system/docker.service.d
			$ sudo systemctl start docker"
			fi
		elif [[ "${CONTAINER_ENGINE}" == "podman" ]]; then
			echo_console_error "'${CONTAINER_ENGINE}' is not available. Please install it and start the '${CONTAINER_ENGINE}' container engine."
		fi
		exit 1
	else
		# Check if the docker daemon is running
		set +e
		${CONTAINER_ENGINE} info >/dev/null 2>&1
		if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
			if [[ "${CONTAINER_ENGINE}" == "docker" ]]; then
				if [[ "${IS_MAC}" == "true" ]]; then
					echo_console_error "The docker daemon is not running! Please start it ([MacOS] '$ open /Applications/Docker.app')."
				else
					echo_console_error "The docker daemon is not running! Please start it ([CentoOS/RHEL/Fedora] '$ sudo systemctl start docker')."
				fi
			elif [[ "${CONTAINER_ENGINE}" == "podman" ]]; then
				if [[ "${IS_MAC}" == "true" ]]; then
					echo_console_error "The podman machine is not running! Please start it ([MacOS] '$ podman machine stop; podman machine rm -f; podman machine init --cpus 8 --memory 16384 --disk-size 20 --rootful; podman machine start')."
				else
					echo_console_error "The podman machine is not running! Please start it."
				fi
			fi
			exit 1
		fi
		set -e
	fi
}

function simple_check_and_download() {
	NAME="${1}"
	DIST="${DIST_DIR}/${2}"
	URL="${3}"
	VERSION="${4}"
	if [ -f "${DIST}" ]; then
		echo "[INFO] '${NAME}' (${VERSION}) is already available"
	else
		echo "Downloading '${NAME}' (${VERSION})"
		set +e
		wget --user-agent 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_1_2 AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36' -q -O "${DIST}" "${URL}"
		RC=$?
		if [[ ${RC} -ne 0 ]]; then
			echo_console_error "Error while downloading '${URL}' (Return code: ${RC})"
			rm -f "${DIST}"
		fi
		set -e
	fi
}

function remove_container_images() {
	NAME="${1}"
	set +e
	${CONTAINER_ENGINE} images -a | grep "${NAME}" | awk '{print $3}' | xargs -r "${CONTAINER_ENGINE}" rmi --force
	set -e
}

function download_container_image() {
	NAME="${1}"
	CONTAINER_IMAGE_NAME="${2}"
	LOCAL_IMG="${3}"
	PLATFORM=${4:-${CONTAINER_PLATFORM}}
	# Extract "REPO" and "VERSION" from container image name
	REPO="${CONTAINER_IMAGE_NAME%%:*}"
	VERSION="${CONTAINER_IMAGE_NAME#*:}"
	if [[ -f "${DIST_DIR}/${LOCAL_IMG}" ]]; then
		echo "[INFO] '${NAME}' (${VERSION}) is already available"
	else
		echo "[INFO] Downloading '${NAME}' (${VERSION}) ${CONTAINER_ENGINE} image"
		# Delete previous versions
		IMAGE_INAME=$(echo "${LOCAL_IMG}" | rev | cut -d '_' -f 2- | rev | sed 's/$/_*.img/')
		find "${DIST_DIR}" -type f -iname "${IMAGE_INAME}" -delete
		remove_container_images "${REPO}"
		${CONTAINER_ENGINE} pull --platform "${PLATFORM}" "${REPO}:${VERSION}"
		${CONTAINER_ENGINE} image save "${REPO}:${VERSION}" | gzip >"${DIST_DIR}/${LOCAL_IMG}"
	fi
}

check_container_engine

##############################################################################################################
# 00 Mustache
##############################################################################################################
MUSTACHE="../../templating/mo_${MUSTACHE_VERSION}"
DIST_MO="${DIST_DIR}/templating/mo_${MUSTACHE_VERSION}"
if [ -f "${DIST_MO}" ]; then
	echo "[INFO] 'Mustache' (${MUSTACHE_VERSION}) is already available"
else
	find "${SCRIPT_PATH}/../../dist/templating" -type f -mindepth 1 -maxdepth 1 -iname 'mo*' ! -name mo_${MUSTACHE_VERSION} -delete
	simple_check_and_download "Mustache" "templating/mo_${MUSTACHE_VERSION}" "https://raw.githubusercontent.com/tests-always-included/mo/${MUSTACHE_VERSION}/mo" "${MUSTACHE_VERSION}"
	chmod +x "${DIST_DIR}/templating/mo_${MUSTACHE_VERSION}"
	if [[ -n "$(command -v shfmt)" ]]; then
		shfmt -l -w "${DIST_DIR}/templating/mo_${MUSTACHE_VERSION}" &>/dev/null
	fi
fi

##############################################################################################################
# 01 Fernflower
##############################################################################################################
echo_console_tool_info "01 - Fernflower v${FERNFLOWER_VERSION}"
DIST_FERNFLOWER="${DIST_DIR}/oci__fernflower_${FERNFLOWER_VERSION}.img"
if [ -f "${DIST_FERNFLOWER}" ]; then
	echo "[INFO] 'Fernflower' (${FERNFLOWER_VERSION}) is already available"
else
	mkdir -p "${DIST_DIR}/containerized/fernflower"

	# Delete previous versions
	find "${DIST_DIR}" -type f -iname 'oci__fernflower*.img' -delete
	find "${DIST_DIR}" -type f -iname 'fernflower_*.jar' -delete

	# Build container image
	pushd "${SCRIPT_PATH}/../../dist/containerized/fernflower" &>/dev/null
	${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" \
		--build-arg IMG_GRADLE="${IMG_GRADLE_8_JDK_21}" \
		--build-arg IMG_JAVA="${IMG_ECLIPSE_TEMURIN_21}" \
		--build-arg FERNFLOWER_VERSION="${FERNFLOWER_VERSION}" \
		-f "Dockerfile" -t "${CONTAINER_IMAGE_NAME_FERNFLOWER}" .
	popd &>/dev/null

	${CONTAINER_ENGINE} image save "${CONTAINER_IMAGE_NAME_FERNFLOWER}" | gzip >"${DIST_FERNFLOWER}"
fi

##############################################################################################################
# 02 CSA
##############################################################################################################
echo_console_tool_info "02 - CSA v${CSA_VERSION}"
DIST_CSA="${DIST_DIR}/oci__csa_${CSA_VERSION}.img"
if [ -f "${DIST_CSA}" ]; then
	echo "[INFO] 'CSA' (${CSA_VERSION}) is already available"
else
	mkdir -p "${DIST_DIR}/containerized/csa"

	# Delete previous versions
	find "${DIST_DIR}" -type f -iname 'oci__csa*.img' ! -name 'oci__csa*bagger*.img' -delete
	find "${DIST_DIR}" -type f -iname 'cloud-suitability-analyzer-*.zip' -delete

	# wget -q -O "csa-l" "https://github.com/vmware-tanzu/cloud-suitability-analyzer/releases/download/v${CSA_VERSION}/csa-l"
	# wget -q -O "csa" "https://github.com/vmware-tanzu/cloud-suitability-analyzer/releases/download/v${CSA_VERSION}/csa"
	# wget -q -O "CSA-UserManual.pdf" "https://github.com/vmware-tanzu/cloud-suitability-analyzer/releases/download/v${CSA_VERSION}/CSA-UserManual.pdf"

	# Build container image
	pushd "${SCRIPT_PATH}/../../dist/containerized/csa" &>/dev/null
	CSA_ARCH="$([[ "${ARCH}" == "arm64" ]] && echo "arm64" || echo "x86_64")"
	${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" \
		--build-arg ARCH="${CSA_ARCH}" \
		--build-arg CSA_VERSION="${CSA_VERSION}" \
		--build-arg IMG_BUILD="ubuntu:24.04" \
		--build-arg IMG_BASE="gcr.io/distroless/static-debian12" \
		-f "Dockerfile" -t "${CONTAINER_IMAGE_NAME_CSA}" .
	#--build-arg IMG_BUILD="alpine:latest" \
	#--build-arg IMG_SHELL="busybox:1.36.1-uclibc" \
	popd &>/dev/null

	${CONTAINER_ENGINE} image save "${CONTAINER_IMAGE_NAME_CSA}" | gzip >"${DIST_CSA}"
fi

# 02 CSA - Bagger build
echo_console_tool_info "02 - CSA - Bagger v${CSA_BAGGER_VERSION}"
DIST_CSA_BAGGER="${DIST_DIR}/oci__csa-bagger_${CSA_BAGGER_VERSION}.img"
if [ -f "${DIST_CSA_BAGGER}" ]; then
	echo "[INFO] 'CSA Bagger' (${CSA_BAGGER_VERSION}) is already available"
else
	mkdir -p "${DIST_DIR}/containerized/csa-bagger"

	# Delete previous versions
	find "${DIST_DIR}" -type f -iname 'oci__csa*bagger*.img' -delete
	find "${DIST_DIR}" -type f -iname 'bagger_*.jar' -delete

	# Build container image
	pushd "${SCRIPT_PATH}/../../dist/containerized/csa-bagger" &>/dev/null
	${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" \
		--build-arg CSA_BAGGER_VERSION="${CSA_BAGGER_VERSION}" \
		--build-arg IMG_MAVEN="${IMG_MAVEN_3_JDK_21}" \
		--build-arg IMG_SLIM="debian:12.5-slim" \
		-f "Dockerfile" -t "${CONTAINER_IMAGE_NAME_CSA_BAGGER}" .
	popd &>/dev/null

	${CONTAINER_ENGINE} image save "${CONTAINER_IMAGE_NAME_CSA_BAGGER}" | gzip >"${DIST_CSA_BAGGER}"
fi

##############################################################################################################
# 03 Windup
##############################################################################################################
echo_console_tool_info "03 - Windup v${WINDUP_VERSION}"
DIST_WINDUP="${DIST_DIR}/oci__windup_${WINDUP_VERSION}.img"
if [ -f "${DIST_WINDUP}" ]; then
	echo "[INFO] 'Windup' (${WINDUP_VERSION}) is already available"
else
	# 03 Windup (https://windup.github.io/downloads/)
	echo "[INFO] Downloading 'Windup'"
	mkdir -p "${DIST_DIR}/containerized/windup"

	# Delete previous versions
	find "${SCRIPT_PATH}/../../dist/containerized/windup/" -type f -iname '*-offline.zip' ! -name windup-cli-${WINDUP_VERSION}.Final-offline.zip -delete
	find "${SCRIPT_PATH}/../../dist/containerized/windup/" -type f -iname '*-offline.zip.orig' ! -name windup-cli-${WINDUP_VERSION}.Final-offline.zip.orig -delete
	find "${DIST_DIR}" -type f -iname 'oci__windup*.img' -delete

	# Download
	simple_check_and_download "Windup" "containerized/windup/windup-cli-${WINDUP_VERSION}.Final-offline.zip.orig" "https://repo1.maven.org/maven2/org/jboss/windup/windup-cli/${WINDUP_VERSION}.Final/windup-cli-${WINDUP_VERSION}.Final-offline.zip" "${WINDUP_VERSION}"

	# Build container image
	pushd "${SCRIPT_PATH}/../../dist/containerized/windup" &>/dev/null

	# Patching latest version to fix https://github.com/windup/windup/pull/1632
	if [ -d "./patch" ]; then
		WINDUP_HYPHEN_VERSION=$(echo ${WINDUP_VERSION} | tr '.' '-')
		rm -Rf windup-cli-${WINDUP_VERSION}.Final
		unzip ./windup-cli-${WINDUP_VERSION}.Final-offline.zip.orig &>/dev/null
		cd patch
		jar uf ../windup-cli-${WINDUP_VERSION}.Final/lib/windup-rules-java-api-${WINDUP_VERSION}.Final.jar org/jboss/windup/rules/apps/java/reporting/freemarker/dto/DependencyGraphItem.class org/jboss/windup/rules/apps/java/reporting/freemarker/dto/DependencyGraphItem\$Kind.class
		jar uf ../windup-cli-${WINDUP_VERSION}.Final/addons/org-jboss-windup-rules-apps-windup-rules-java-${WINDUP_HYPHEN_VERSION}-Final/windup-rules-java-api-${WINDUP_VERSION}.Final.jar org/jboss/windup/rules/apps/java/reporting/freemarker/dto/DependencyGraphItem.class org/jboss/windup/rules/apps/java/reporting/freemarker/dto/DependencyGraphItem\$Kind.class
		jar uf ../windup-cli-${WINDUP_VERSION}.Final/addons/org-jboss-windup-reporting-windup-reporting-${WINDUP_HYPHEN_VERSION}-Final/windup-reporting-impl-${WINDUP_VERSION}.Final.jar reports/resources/css/topology-graph.css reports/resources/js/app-dependency-graph.js reports/templates/dependency_graph.ftl
		cd ..
		zip -r windup-cli-${WINDUP_VERSION}.Final-offline.zip "./windup-cli-${WINDUP_VERSION}.Final" &>/dev/null
		rm -Rf "./windup-cli-${WINDUP_VERSION}.Final"
	else
		cp -f windup-cli-${WINDUP_VERSION}.Final-offline.zip.orig windup-cli-${WINDUP_VERSION}.Final-offline.zip
	fi

	${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" \
		--build-arg IMG_BASE="alpine:latest" \
		--build-arg IMG_JAVA="${IMG_ECLIPSE_TEMURIN_11}" \
		--build-arg WINDUP_VERSION="${WINDUP_VERSION}" \
		-f "Dockerfile" -t "${CONTAINER_IMAGE_NAME_WINDUP}" .

	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${CONTAINER_IMAGE_NAME_WINDUP}" | gzip >"${DIST_WINDUP}"
fi

##############################################################################################################
# 04 IBM WAMT
##############################################################################################################
echo_console_tool_info "04 - WAMT v${WAMT_VERSION}"
DIST_IBM_WAMT="${DIST_DIR}/oci__wamt_${WAMT_VERSION}.img"
if [ -f "${DIST_IBM_WAMT}" ]; then
	echo "[INFO] 'IBM WAMT' (${WAMT_VERSION}) is already available"
else
	WAMT_DIR="${DIST_DIR}/containerized/wamt"
	WAMT_INSTALLER="${WAMT_DIR}/binaryAppScannerInstaller.jar"
	WAMT_ZIP="${WAMT_DIR}/wamt-${WAMT_VERSION}.zip"
	TMP_DIR="${DIST_DIR}/tmp"

	mkdir -p "${WAMT_DIR}" "${TMP_DIR}"
	rm -f "${WAMT_INSTALLER}"
	rm -Rf "${TMP_DIR}"

	# Delete previous versions
	find "${SCRIPT_PATH}/../../dist/containerized/wamt/" -type f -iname '*wamt*.zip' ! -name wamt-${WAMT_VERSION}.zip -delete
	find "${DIST_DIR}" -type f -iname 'oci__wamt_*.img' -delete

	if [ -f "${WAMT_ZIP}" ]; then
		echo "[INFO] 'IBM WAMT zip' (wamt-${WAMT_VERSION}.zip) is already available"
	else
		simple_check_and_download "IBM WAMT" "containerized/wamt/binaryAppScannerInstaller.jar" "https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/wasdev/downloads/wamt/ApplicationBinaryTP/binaryAppScannerInstaller.jar" "${WAMT_VERSION}"
		unzip "${WAMT_INSTALLER}" -d "${TMP_DIR}" &>/dev/null

		pushd "${TMP_DIR}" &>/dev/null
		rm -f wamt/*.pdf
		zip -r "wamt-${WAMT_VERSION}.zip" ./wamt &>/dev/null
		popd &>/dev/null

		mv "${TMP_DIR}/wamt-${WAMT_VERSION}.zip" "${WAMT_ZIP}"
		rm -Rf "${TMP_DIR}"
		rm -f "${WAMT_INSTALLER}"
	fi

	# Build container image
	pushd "${SCRIPT_PATH}/../../dist/containerized/wamt" &>/dev/null
	${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" \
		--build-arg IMG_BASE="alpine:latest" \
		--build-arg IMG_JAVA="${IMG_ECLIPSE_TEMURIN_21}-alpine" \
		--build-arg WAMT_VERSION="${WAMT_VERSION}" \
		-f "Dockerfile" -t "${CONTAINER_IMAGE_NAME_WAMT}" .
	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${CONTAINER_IMAGE_NAME_WAMT}" | gzip >"${DIST_IBM_WAMT}"
fi

##############################################################################################################
# 05 OWASP DC
##############################################################################################################
echo_console_tool_info "05 - OWASP DC v${OWASP_DC_VERSION}"

ODC_IMG="${DIST_DIR}/oci__owasp-dependency-check_${OWASP_DC_VERSION}.img"
if [[ -f "${ODC_IMG}" ]]; then
	echo "[INFO] 'OWASP DC' (${OWASP_DC_VERSION}) is already available"
else
	echo "[INFO] Downloading and building 'OWASP DC' (${OWASP_DC_VERSION}) ${CONTAINER_ENGINE} image"

	# Delete previous versions
	find "${DIST_DIR}" -type f -iname 'oci__owasp-dependency-check_*.img' -delete
	find "${DIST_DIR}/containerized/owasp-dependency-check" -type f -iname 'owasp-dependency-check*.zip' ! -name "owasp-dependency-check_${OWASP_DC_VERSION}.zip" -delete

	ODC_SHORT_ZIP="containerized/owasp-dependency-check/owasp-dependency-check_${OWASP_DC_VERSION}.zip"

	simple_check_and_download "OWASP Dependency-Check" "${ODC_SHORT_ZIP}" "https://github.com/jeremylong/DependencyCheck/releases/download/v${OWASP_DC_VERSION}/dependency-check-${OWASP_DC_VERSION}-release.zip" "${OWASP_DC_VERSION}"

	# Build container image
	pushd "${SCRIPT_PATH}/../../dist/containerized/owasp-dependency-check" &>/dev/null
	${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" \
		--build-arg IMG_GO="golang:1.22.1-alpine" \
		--build-arg IMG_JLINK="azul/zulu-openjdk-alpine:20" \
		--build-arg IMG_DOTNET_RUNTIME="${IMG_DOTNET_RUNTIME}" \
		--build-arg VERSION="${OWASP_DC_VERSION}" \
		-f "Dockerfile" -t "${CONTAINER_IMAGE_NAME_OWASP_DC}" .
	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${CONTAINER_IMAGE_NAME_OWASP_DC}" | gzip >"${ODC_IMG}"
fi

simple_check_and_download "Nist Data Mirror" "containerized/owasp-dependency-check/nist-data-mirror.jar" "https://github.com/stevespringett/nist-data-mirror/releases/download/nist-data-mirror-${NIST_MIRROR_VERSION}/nist-data-mirror.jar" "${NIST_MIRROR_VERSION}"

if [[ "${UPDATE_VULN_DBS}" == "true" ]]; then
	DATA_DIR="${DIST_DIR}/owasp_data"
	mkdir -p "${DATA_DIR}/cache" "${DATA_DIR}/nvdcache"

	# Download and cache locally the NVD and RetireJS databases for the OWASP analysis
	echo "[INFO] Updating local RetireJS cache ..."
	wget -q -O "${DATA_DIR}/jsrepository.json" "https://raw.githubusercontent.com/Retirejs/retire.js/master/repository/jsrepository.json"

	# FIXME - Remove Java usage and bump to latest version
	if [[ -n "$(command -v javac)" ]]; then
		echo "[INFO] Updating local NVD cache ..."
		set +e
		java -jar "${DIST_DIR}/containerized/owasp-dependency-check/nist-data-mirror.jar" "${DATA_DIR}/nvdcache"
		set -e
	fi
fi

##############################################################################################################
# 06 ScanCode Toolkit
##############################################################################################################
echo_console_tool_info "06 - ScanCode v${SCANCODE_VERSION}"
SC_IMG="${DIST_DIR}/oci__scancode-toolkit_${SCANCODE_VERSION}.img"
if [[ -f "${SC_IMG}" ]]; then
	echo "[INFO] 'ScanCode' (${SCANCODE_VERSION}) is already available"
else
	echo "[INFO] Downloading and building 'ScanCode' (${SCANCODE_VERSION}) ${CONTAINER_ENGINE} image"

	# Delete previous versions
	find "${DIST_DIR}" -type f -iname 'oci__scancode-toolkit_*.img' -delete
	find "${DIST_DIR}/containerized/scancode-toolkit" -type f -iname 'scancode_*.zip' ! -name "scancode_${SCANCODE_VERSION}.zip" -delete

	exec 6>/dev/null
	# Remove existing and build Scancode container image
	remove_container_images "scancode-toolkit"

	mkdir -p "${DIST_DIR}/containerized/scancode-toolkit"

	SC_SHORT_ZIP="containerized/scancode-toolkit/scancode_${SCANCODE_VERSION}.zip"
	SC_ZIP="${DIST_DIR}/${SC_SHORT_ZIP}"
	simple_check_and_download "Scancode" "${SC_SHORT_ZIP}" "https://github.com/nexB/scancode-toolkit/archive/refs/tags/v${SCANCODE_VERSION}.zip" "${SCANCODE_VERSION}"

	# Build ScanCode container image
	TMP_SCANCODE_BUILD_DIR="/tmp/sc"
	rm -Rf "${TMP_SCANCODE_BUILD_DIR}"
	mkdir -p "${TMP_SCANCODE_BUILD_DIR}"

	set +e
	unzip -o -P pass "${SC_ZIP}" -d "${TMP_SCANCODE_BUILD_DIR}" >&6 2>&1
	set -e

	pushd "${TMP_SCANCODE_BUILD_DIR}/scancode-toolkit-${SCANCODE_VERSION}" &>/dev/null

	# Replace Scancode with in-memory cache workaround
	rm scancode
	cp "${SCRIPT_PATH}/../../dist/containerized/scancode-toolkit/scancode" .
	chmod +x scancode

	# Fix html-app markup
	wget -q -O "src/formattedcode/templates/html-app/assets/jquery.min.map" "https://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.3/jquery.min.map"
	rm src/formattedcode/templates/html-app/assets/scancode_datatable.js
	cp "${SCRIPT_PATH}/../../dist/containerized/scancode-toolkit/scancode_datatable.js" src/formattedcode/templates/html-app/assets/scancode_datatable.js
	rm src/formattedcode/templates/html-app/template.html
	cp "${SCRIPT_PATH}/../../dist/containerized/scancode-toolkit/template.html" src/formattedcode/templates/html-app/template.html

	# Build container image
	${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" -t "${CONTAINER_IMAGE_NAME_SCANCODE}" .

	popd &>/dev/null

	# Cleanup
	rm -Rf "${TMP_SCANCODE_BUILD_DIR}"
	${CONTAINER_ENGINE} image save "${CONTAINER_IMAGE_NAME_SCANCODE}" | gzip >"${SC_IMG}"
fi

##############################################################################################################
# 07 PMD
##############################################################################################################
echo_console_tool_info "07 - PMD v${PMD_VERSION}"

DIST_PMD="${DIST_DIR}/oci__pmd_${PMD_VERSION}.img"
if [ -f "${DIST_PMD}" ]; then
	echo "[INFO] 'PMD' (${PMD_VERSION}) is already available"
else
	echo "[INFO] Downloading 'PMD'"
	mkdir -p "${DIST_DIR}/containerized/pmd"

	# Delete previous versions
	find "${DIST_DIR}/" -type f -maxdepth 1 -mindepth 1 -iname 'pmd-*.zip' -delete
	find "${DIST_DIR}/" -type f -maxdepth 1 -mindepth 1 -iname 'pmd-*.jar' -delete
	find "${SCRIPT_PATH}/../../dist/containerized/pmd/" -type f -iname 'pmd-bin-*.zip' ! -name pmd-bin-${PMD_VERSION}.zip -delete
	simple_check_and_download "PMD" "containerized/pmd/pmd-bin-${PMD_VERSION}.zip" "https://github.com/pmd/pmd/releases/download/pmd_releases%2F${PMD_VERSION}/pmd-dist-${PMD_VERSION}-bin.zip" "${PMD_VERSION}"

	# Build container image
	pushd "${SCRIPT_PATH}/../../dist/containerized/pmd" &>/dev/null
	${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" \
		--build-arg IMG_BASE="alpine:latest" \
		--build-arg IMG_JAVA="${IMG_ECLIPSE_TEMURIN_21}" \
		--build-arg PMD_VERSION="${PMD_VERSION}" \
		-f "Dockerfile" -t "${CONTAINER_IMAGE_NAME_PMD}" .
	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${CONTAINER_IMAGE_NAME_PMD}" | gzip >"${DIST_PMD}"
fi

##############################################################################################################
# 08 Linguist
##############################################################################################################
echo_console_tool_info "08 - Linguist v${LINGUIST_VERSION}"
LINGUIST_IMG="oci__linguist_${LINGUIST_VERSION}.img"
if [[ -f "${DIST_DIR}/${LINGUIST_IMG}" ]]; then
	echo "[INFO] 'Linguist' (${LINGUIST_VERSION}) is already available"
else
	echo "[INFO] Building 'Linguist' (${LINGUIST_VERSION}) ${CONTAINER_ENGINE} image"

	# Delete previous versions
	find "${DIST_DIR}" -type f -iname 'oci__linguist_*.img' -delete

	# Build the latest Linguist container image
	rm -Rf /tmp/linguist
	mkdir /tmp/linguist
	pushd "/tmp/linguist" &>/dev/null
	wget -q -O "linguist.zip" "https://github.com/github/linguist/archive/refs/tags/v${LINGUIST_VERSION}.zip"
	set +e
	unzip "linguist.zip" &>/dev/null
	set -e
	cd "linguist-${LINGUIST_VERSION}"
	rm Dockerfile
	wget -q -O "Dockerfile" https://raw.githubusercontent.com/crazy-max/docker-linguist/master/Dockerfile
	sed -i '' -e "s/.*ARG LINGUIST_VERSION=.*/ARG LINGUIST_VERSION=\"${LINGUIST_VERSION}\"/" Dockerfile
	${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" -t "${CONTAINER_IMAGE_NAME_LINGUIST}" .
	popd &>/dev/null
	${CONTAINER_ENGINE} image save "${CONTAINER_IMAGE_NAME_LINGUIST}" | gzip >"${DIST_DIR}/${LINGUIST_IMG}"
	rm -Rf /tmp/linguist
fi

##############################################################################################################
# 08 CLOC
##############################################################################################################
echo_console_tool_info "08 - CLOC v${CLOC_VERSION}"
CLOC_DIST="${DIST_DIR}/oci__cloc_${CLOC_VERSION}.img"
if [ -f "${CLOC_DIST}" ]; then
	echo "[INFO] 'CLOC' (${CLOC_VERSION}) is already available"
else
	# Delete previous versions
	find "${SCRIPT_PATH}/../../dist/containerized/cloc/" -type f -iname 'cloc-*.tar.gz' ! -name cloc-${CLOC_VERSION}.tar.gz -delete
	find "${SCRIPT_PATH}/../../dist/" -type f -iname 'cloc-*.tar.gz' -delete
	find "${DIST_DIR}" -type f -iname 'oci__cloc_*.img' -delete

	simple_check_and_download "CLOC" "containerized/cloc/cloc-${CLOC_VERSION}.tar.gz" "https://github.com/AlDanial/cloc/releases/download/v${CLOC_VERSION}/cloc-${CLOC_VERSION}.tar.gz" "${CLOC_VERSION}"
	# Build container image
	pushd "${SCRIPT_PATH}/../../dist/containerized/cloc" &>/dev/null
	${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" \
		--build-arg IMG_BASE="alpine:latest" \
		--build-arg CLOC_VERSION="${CLOC_VERSION}" \
		-f "Dockerfile" -t "${CONTAINER_IMAGE_NAME_CLOC}" .
	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${CONTAINER_IMAGE_NAME_CLOC}" | gzip >"${CLOC_DIST}"
fi

##############################################################################################################
# 09 FindSecBugs
##############################################################################################################
echo_console_tool_info "09 - FindSecBugs v${FSB_VERSION}"
FSB_DIST="${DIST_DIR}/oci__findsecbugs_${FSB_VERSION}.img"
if [ -f "${FSB_DIST}" ]; then
	echo "[INFO] 'FindSecBugs' (${FSB_VERSION}) is already available"
else
	FSB_ZIP="${DIST_DIR}/containerized/findsecbugs/findsecbugs-cli-${FSB_VERSION}.zip"

	# Delete previous versions
	find "${SCRIPT_PATH}/../../dist/containerized/findsecbugs/" -type f -iname 'findsecbugs-cli*.zip' ! -name findsecbugs-cli-${FSB_VERSION}.zip -delete
	find "${DIST_DIR}" -type f -iname 'oci__findsecbugs_*.img' -delete

	if [ -f "${FSB_ZIP}" ]; then
		echo "[INFO] 'FSB zip' (findsecbugs-cli-${FSB_VERSION}.zip) is already available"
	else
		simple_check_and_download "FindSecBugs" "containerized/findsecbugs/findsecbugs-cli-${FSB_VERSION}.zip" "https://github.com/find-sec-bugs/find-sec-bugs/releases/download/version-${FSB_VERSION}/findsecbugs-cli-${FSB_VERSION}.zip" "${FSB_VERSION}"
		TMP_DIR="${DIST_DIR}/tmp"
		TMP_FSB_DIR="${TMP_DIR}/findsecbugs-cli-${FSB_VERSION}"
		rm -Rf "${TMP_DIR}"
		mkdir -p "${TMP_FSB_DIR}"
		unzip "${FSB_ZIP}" -d "${TMP_FSB_DIR}" &>/dev/null

		pushd "${TMP_FSB_DIR}" &>/dev/null
		chmod +x findsecbugs.sh
		# Remove spurious CR characters
		sed -i '' -e 's/\r$//' findsecbugs.sh
		rm -f findsecbugs.bat
		cd ..
		mv "findsecbugs-cli-${FSB_VERSION}" "findsecbugs-cli"
		zip -r "findsecbugs-cli-${FSB_VERSION}.zip" "./findsecbugs-cli" &>/dev/null
		popd &>/dev/null

		mv "${TMP_DIR}/findsecbugs-cli-${FSB_VERSION}.zip" "${FSB_ZIP}"
		rm -Rf "${TMP_DIR}"
	fi

	# Build container image
	pushd "${SCRIPT_PATH}/../../dist/containerized/findsecbugs" &>/dev/null
	${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" \
		--build-arg IMG_BASE="alpine:latest" \
		--build-arg IMG_JAVA="${IMG_ECLIPSE_TEMURIN_11}" \
		--build-arg FSB_VERSION="${FSB_VERSION}" \
		-f "Dockerfile" -t "${CONTAINER_IMAGE_NAME_FSB}" .
	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${CONTAINER_IMAGE_NAME_FSB}" | gzip >"${FSB_DIST}"
fi

##############################################################################################################
# 10 Microsoft Application Inspector (MAI)
##############################################################################################################
echo_console_tool_info "10 - MAI v${MAI_VERSION}"
DIST_MAI="${DIST_DIR}/oci__mai_${MAI_VERSION}.img"
if [ -f "${DIST_MAI}" ]; then
	echo "[INFO] 'MAI' (${DIST_MAI}) is already available"
else
	# Delete previous versions
	find "${SCRIPT_PATH}/../../dist/containerized/mai/" -type f -iname 'ApplicationInspector_netcoreapp_*.zip' ! -name ApplicationInspector_netcoreapp_${MAI_VERSION}.zip -delete
	find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__mai_*.img' -delete

	simple_check_and_download "Microsoft Application Inspector" "containerized/mai/ApplicationInspector_netcoreapp_${MAI_VERSION}.zip" "https://github.com/microsoft/ApplicationInspector/releases/download/v${MAI_VERSION}/ApplicationInspector_netcoreapp_${MAI_VERSION}.zip" "${MAI_VERSION}"

	# Build container image
	pushd "${SCRIPT_PATH}/../../dist/containerized/mai" &>/dev/null
	${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" \
		--build-arg IMG_BASE="alpine:latest" \
		--build-arg IMG_DOTNET_RUNTIME="${IMG_DOTNET_RUNTIME}" \
		--build-arg MAI_VERSION="${MAI_VERSION}" \
		-f "Dockerfile" -t "${CONTAINER_IMAGE_NAME_MAI}" .
	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${CONTAINER_IMAGE_NAME_MAI}" | gzip >"${DIST_MAI}"
fi

##############################################################################################################
# 11 SAST-Scan
##############################################################################################################
# Loading the latest linguist container image (only for amd64)
if [[ "${ARCH}" == "x86_64" ]]; then
	echo_console_tool_info "11 - SAST-Scan v${SLSCAN_VERSION}"
	find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__sast-scan_*.img' ! -name oci__sast-scan_${SLSCAN_VERSION}.img -delete
	download_container_image 'SAST-Scan (slscan)' "${CONTAINER_IMAGE_NAME_SLSCAN}" "oci__sast-scan_${SLSCAN_VERSION}.img"
fi

##############################################################################################################
# 12 Insider
##############################################################################################################
# Load the latest Insider container image
echo_console_tool_info "12 - Insider v${INSIDER_VERSION}"
find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__insider_*.img' ! -name oci__insider_${INSIDER_VERSION}.img -delete
download_container_image 'Insider' "${CONTAINER_IMAGE_NAME_INSIDER}" "oci__insider_${INSIDER_VERSION}.img" "linux/amd64"

##############################################################################################################
# 13 Grype
##############################################################################################################
# Load the correct Grype container image
echo_console_tool_info "13 - Grype v${GRYPE_VERSION}"
find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__grype_*.img' ! -name oci__grype_${GRYPE_VERSION}.img -delete
download_container_image 'Grype' "${CONTAINER_IMAGE_NAME_GRYPE}" "oci__grype_${GRYPE_VERSION}.img"

# Update Grype DB
if [[ "${UPDATE_VULN_DBS}" == "true" ]]; then
	GRYPE_CACHE_DIR=$(echo "$(cd "$(dirname "${DIST_DIR}/grype_cache")"; pwd)/grype_cache")
	mkdir -p "${GRYPE_CACHE_DIR}"
	${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm -v "${GRYPE_CACHE_DIR}:/db" -e GRYPE_DB_CACHE_DIR="/db" --name Grype "anchore/grype:v${GRYPE_VERSION}" db update
fi

##############################################################################################################
# 13 Syft
##############################################################################################################
# Load the correct Syft container image
echo_console_tool_info "13 - Syft v${SYFT_VERSION}"
find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__syft_*.img' ! -name oci__syft_${SYFT_VERSION}.img -delete
download_container_image 'Syft' "${CONTAINER_IMAGE_NAME_SYFT}" "oci__syft_${SYFT_VERSION}.img"

##############################################################################################################
# 14 Trivy
##############################################################################################################
# Load the correct Trivy container image
echo_console_tool_info "14 - Trivy v${TRIVY_VERSION}"
DIST_TRIVY="${DIST_DIR}/oci__trivy_${TRIVY_VERSION}.img"
if [[ "${UPDATE_VULN_DBS}" == "true" ]]; then
	# Remove current image to force an update of the cache
	find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__trivy_*.img' -delete
	remove_container_images "trivy"
fi
if [ -f "${DIST_TRIVY}" ]; then
	echo "[INFO] 'Trivy' (${TRIVY_VERSION}) is already available"
else
	find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__trivy_*.img' ! -name oci__trivy_${TRIVY_VERSION}.img -delete

	# Build container image including cache as it otherwise does not work in an airgapped environmment with podman
	## https://aquasecurity.github.io/trivy/v0.43/docs/advanced/air-gap/
	pushd "${SCRIPT_PATH}/../../dist/containerized/trivy" &>/dev/null
	${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" \
		--build-arg TRIVY_VERSION="${TRIVY_VERSION}" \
		-f "Dockerfile" -t "${CONTAINER_IMAGE_NAME_TRIVY}" .
	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${CONTAINER_IMAGE_NAME_TRIVY}" | gzip >"${DIST_TRIVY}"
fi

##############################################################################################################
# 15 OSV
##############################################################################################################
# Load the correct OSV container image
echo_console_tool_info "15 - OSV v${OSV_VERSION}"
DIST_OSV="${DIST_DIR}/oci__osv_${OSV_VERSION}.img"
if [ -f "${DIST_OSV}" ]; then
	echo "[INFO] 'OSV' (${OSV_VERSION}) is already available"
else
	find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__osv_*.img' ! -name oci__osv_${OSV_VERSION}.img -delete
	download_container_image 'OSV' "${CONTAINER_IMAGE_NAME_OSV}" "oci__osv_${OSV_VERSION}.img"
fi

##############################################################################################################
# 17 Bearer
##############################################################################################################
echo_console_tool_info "17 - Bearer v${BEARER_VERSION}"
DIST_BEARER="${DIST_DIR}/oci__bearer_${BEARER_VERSION}.img"
if [ -f "${DIST_BEARER}" ]; then
	echo "[INFO] 'Bearer' (${BEARER_VERSION}) is already available"
else
	# Delete previous versions
	find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__bearer_*.img' ! -name oci__bearer_${BEARER_VERSION}.img -delete

	# Build container image (custom build as official image only available for x86)
	pushd "${SCRIPT_PATH}/../../dist/containerized/bearer" &>/dev/null
	${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" \
		--build-arg IMG_BUILD="ubuntu:24.04" \
		--build-arg IMG_BASE="ubuntu:24.04" \
		--build-arg BEARER_VERSION="${BEARER_VERSION}" \
		-f "Dockerfile" -t "${CONTAINER_IMAGE_NAME_BEARER}" .
	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${CONTAINER_IMAGE_NAME_BEARER}" | gzip >"${DIST_BEARER}"
fi

##############################################################################################################
# 99 Reports - Update imported static content
##############################################################################################################
echo_console_tool_info "99 - Static content"

JS_DIR="${DIST_DIR}/templating/static/js"
mkdir -p "${JS_DIR}"

find "${SCRIPT_PATH}/../../dist/templating/static/js" -type f -iname 'd3.v*.min.js' ! -name d3.v4.min.js ! -name d3.v${D3_VERSION}.min.js -delete
simple_check_and_download "JavaScript - D3.js" "templating/static/js/d3.v4.min.js" 'https://unpkg.com/d3@4.13.0/build/d3.min.js' "4.13.0"
simple_check_and_download "JavaScript - D3.js" "templating/static/js/d3.v${D3_VERSION}.min.js" "https://unpkg.com/d3@${D3_VERSION}/dist/d3.min.js" "${D3_VERSION}"

find "${SCRIPT_PATH}/../../dist/templating/static/js" -type f -iname 'jquery-*.min.js' ! -name jquery-${JQUERY_VERSION}.min.js -delete
simple_check_and_download "JavaScript - jQuery" "templating/static/js/jquery-${JQUERY_VERSION}.min.js" "https://unpkg.com/jquery@${JQUERY_VERSION}/dist/jquery.min.js" "${JQUERY_VERSION}"

if [ -f "${JS_DIR}/timelines-chart-${TIMELINES_CHART_VERSION}.min.js" ]; then
	echo "[INFO] 'JavaScript - Timelines Chart' (${TIMELINES_CHART_VERSION}) is already available"
else
	find "${SCRIPT_PATH}/../../dist/templating/static/js" -type f -iname 'timelines-chart*.min.js' -delete
	simple_check_and_download "JavaScript - Timelines Chart" "templating/static/js/timelines-chart-${TIMELINES_CHART_VERSION}.min.js" "https://unpkg.com/timelines-chart@${TIMELINES_CHART_VERSION}/dist/timelines-chart.min.js" "${TIMELINES_CHART_VERSION}"
fi

##############################################################################################################
# Bootstrap
##############################################################################################################
DIST_STATIC="${DIST_DIR}/templating/static"
DIST_BOOTSTRAP="${DIST_STATIC}/bootstrap-${BOOTSTRAP_VERSION}-dist"
if [ -d "${DIST_BOOTSTRAP}" ]; then
	echo "[INFO] 'Bootstrap' (${BOOTSTRAP_VERSION}) is already available"
else
	mkdir -p "${DIST_STATIC}"
	# Delete previous folder and distributions
	find "${SCRIPT_PATH}/../../dist/templating/static" -type f -iname 'bootstrap-*-dist.zip' ! -name bootstrap-${BOOTSTRAP_VERSION}-dist.zip -delete

	simple_check_and_download "Bootstrap" "templating/static/bootstrap-${BOOTSTRAP_VERSION}-dist.zip" "https://github.com/twbs/bootstrap/releases/download/v${BOOTSTRAP_VERSION}/bootstrap-${BOOTSTRAP_VERSION}-dist.zip" "${BOOTSTRAP_VERSION}"

	pushd "${SCRIPT_PATH}/../../dist/templating/static" &>/dev/null
	rm -Rf bootstrap-*-dist
	unzip bootstrap-${BOOTSTRAP_VERSION}-dist.zip &>/dev/null
	find bootstrap-${BOOTSTRAP_VERSION}-dist/css -type f ! -iname 'bootstrap.min.css*' -delete
	find bootstrap-${BOOTSTRAP_VERSION}-dist/js -type f ! -iname 'bootstrap.bundle.min.js*' -delete
	rm -f bootstrap-${BOOTSTRAP_VERSION}-dist.zip
	popd &>/dev/null
fi

DIST_BOOTSTRAP_ICONS="${DIST_STATIC}/css/bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}.css"
if [ -f "${DIST_BOOTSTRAP_ICONS}" ]; then
	echo "[INFO] 'Bootstrap Icons' (${BOOTSTRAP_ICONS_VERSION}) is already available"
else
	mkdir -p "${DIST_STATIC}/css" "${DIST_STATIC}/fonts"
	find "${SCRIPT_PATH}/../../dist/templating/static/css" -type f -iname 'bootstrap-icons-*.css' -delete
	find "${SCRIPT_PATH}/../../dist/templating/static/fonts" -type f -iname 'bootstrap-icons.*' -delete
	simple_check_and_download "Bootstrap Icons" "templating/static/bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}.zip" "https://github.com/twbs/icons/releases/download/v${BOOTSTRAP_ICONS_VERSION}/bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}.zip" "${BOOTSTRAP_ICONS_VERSION}"
	pushd "${SCRIPT_PATH}/../../dist/templating/static" &>/dev/null
	rm -Rf bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}/
	unzip bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}.zip &>/dev/null
	cp -f bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}/font/bootstrap-icons.css css/bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}.css
	cp -f bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}/font/fonts/* fonts/.
	rm -Rf bootstrap-icons-*
	popd &>/dev/null
fi

##############################################################################################################
# Images, Logos, Favicon, Fonts, Scripts
##############################################################################################################

echo "[INFO] Downloading and transforming all required images"
mkdir -p "${DIST_STATIC}/img/"
pushd "${SCRIPT_PATH}/../../dist/containerized/external-assets-downloader" &>/dev/null
${CONTAINER_ENGINE} buildx build --platform "${CONTAINER_PLATFORM}" -f "Dockerfile" -t "${CONTAINER_IMAGE_NAME_ASSET_DOWNLOADER}" . &>/dev/null
${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm -v "${SCRIPT_PATH}/../../dist/templating/static/img:/out/public/img:delegated" --name Downloader "${CONTAINER_IMAGE_NAME_ASSET_DOWNLOADER}"
popd &>/dev/null

# https://github.com/vmware/clarity
if [ -f "${DIST_STATIC}/fonts/Metropolis-Light.ttf" ]; then
	echo "[INFO] 'Font - Metropolis' (latest) is already available"
else
	simple_check_and_download "Font - Metropolis" "templating/static/fonts/Metropolis.zip" 'https://github.com/vmware/clarity/files/5425574/Metropolis.zip' "latest"
	mkdir -p "${DIST_STATIC}/fonts/"
	pushd "${DIST_STATIC}/fonts/" &>/dev/null
	unzip Metropolis.zip &>/dev/null
	rm -Rf __MACOSX Metropolis.zip
	rm -f Metropolis-ExtraLight.ttf Metropolis-LightItalic.ttf Metropolis-Regular.ttf
	popd &>/dev/null
fi

# https://github.com/pgdurand/github-release-api/
simple_check_and_download "Script - git_tag_manager.sh" "../util/00__release/git_tag_manager.sh" 'https://raw.githubusercontent.com/pgdurand/github-release-api/master/git_tag_manager.sh' "latest"
simple_check_and_download "Script - github_release_api.sh" "../util/00__release/github_release_api.sh" 'https://raw.githubusercontent.com/pgdurand/github-release-api/master/github_release_api.sh' "latest"
simple_check_and_download "Script - github_release_manager.sh" "../util/00__release/github_release_manager.sh" 'https://raw.githubusercontent.com/pgdurand/github-release-api/master/github_release_manager.sh' "latest"
simple_check_and_download "Script - json-v2.sh" "../util/00__release/json-v2.sh" 'https://raw.githubusercontent.com/pgdurand/github-release-api/master/json-v2.sh' "latest"

chmod +x "${SCRIPT_DIR}/../00__release/"*.sh

# Remove dangling images
if [ -n "$(${CONTAINER_ENGINE} images -f "dangling=true" -q --no-trunc)" ]; then
    ${CONTAINER_ENGINE} rmi $(${CONTAINER_ENGINE} images -f "dangling=true" -q --no-trunc)
fi
