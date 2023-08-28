#!/usr/bin/env bash
# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Download and containerize all tools instrumented by "Application Portfolio Auditor" and several supportive frameworks and libraries.
#
# The container images built by this script are only valid for systems having the same processor architecture (e.g. x86/ARM/x64).
##############################################################################################################

# ----- Please adjust

# Set to true to get update all local vulnerability databases updated
UPDATE_VULN_DBS=true

# Basis Dotnet runtime image used to build MAI (https://mcr.microsoft.com/v2/dotnet/runtime/tags/list)
## curl -fsSL 'https://mcr.microsoft.com/v2/dotnet/runtime/tags/list' |grep 'alpine'| grep -v 'preview' | grep -v 'amd64'|grep -v 'arm' |sort|tail -1|tr -d ' ,"'
DOTNET_RUNTIME_TAG="mcr.microsoft.com/dotnet/runtime:7.0.9-alpine3.18"

# ------ Do not modify
[[ "$DEBUG" == "true" ]] && set -x
set -eu
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
HOME_DIR="${SCRIPT_DIR}/../.."
export DIST_DIR="${HOME_DIR}/dist"
export DIST_BIN="${HOME_DIR}/bin"

# shellcheck source=/dev/null
source "${HOME_DIR}/_versions.sh"

# Determining platform architecture for the build
ARCH="$(uname -m)"
export DOCKER_ARCH="$([[ "${ARCH}" == "arm64" ]] && echo "arm64" || echo "amd64")"
export DOCKER_PLATFORM="linux/${DOCKER_ARCH}"

## Multiple platform build currently not supported
# export DOCKER_PLATFORM="linux/amd64,linux/arm64"

NORMAL='\033[0m'
BLUE='\033[1;34m'
RED='\033[0;31m'
ORANGE='\033[0;33m'

function log_tool_info() {
	echo -e "\n${BLUE}${*}${NORMAL}"
}

function log_error() {
	echo -e "${RED}${*}${NORMAL}"
}

function log_warn() {
	echo -e "${ORANGE}${*}${NORMAL}"
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
		wget --user-agent 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36' -q -O "${DIST}" "${URL}"
		RC=$?
		if [[ ${RC} -ne 0 ]]; then
			log_error "Error while downloading '${URL}' (Return code: ${RC})"
			rm -f "${DIST}"
		fi
		set -e
	fi
}

function remove_container_images() {
  NAME="${1}"
  ${CONTAINER_ENGINE} images -a | grep "${NAME}" | awk '{print $3}' | xargs "${CONTAINER_ENGINE}" rmi --force
}

function download_container_image() {
	NAME="${1}"
	VERSION="${2}"
	REPO="${3}"
	LOCAL_IMG="${4}"
	PLATFORM=${5:-${DOCKER_PLATFORM}}
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

function check_java_version() {
	# Java version validation for the build
	NEEDED_JAVA_VERSION=${JAVA_VERSION}
	echo "Check Java version (>=${NEEDED_JAVA_VERSION})"
	if [[ -n "$(command -v javac)" ]]; then
		if javac -version 2>&1 | grep -q 'No Java runtime present'; then
			echo "No Java runtime present. Please install Java ${NEEDED_JAVA_VERSION}."
			exit 1
		else
			JAVA_VERSION_CURRENT=$(javac -version 2>&1 | grep 'javac' | awk '{print $2}')
			JAVA_VERSION_MAJOR="$(echo "${JAVA_VERSION_CURRENT}" 2>&1 | cut -d . -f 1)"
			COUNT_ZULU=$(java -version 2>&1 | grep -c 'Zulu' || true)
			if ((COUNT_ZULU > 0)); then
				echo "Wrong JDK provider in use ('Zulu'). Please switch to a non-Zulu JDK."
				exit 1
			elif [ ${JAVA_VERSION_MAJOR} -lt ${NEEDED_JAVA_VERSION} ]; then
				echo "Wrong Java version ('${JAVA_VERSION_CURRENT}') in use. Please switch to Java ${NEEDED_JAVA_VERSION}."
				exit 1
			fi
		fi
	else
		echo "Java is not available. Please install Java ${NEEDED_JAVA_VERSION} or later."
		exit 1
	fi
}

function check_built_java_version() {
	CLASS="${1}"
	if [[ -n "$(command -v od)" ]]; then
		JAVA_VERSION_BUILD=$(od -t d -j 7 -N 1 "${CLASS}" | head -1 | awk '{print $2 - 44}')
		if [[ "${JAVA_VERSION_BUILD}" != "${JAVA_VERSION}" ]]; then
			log_error "Build JAR (Java ${JAVA_VERSION_BUILD}) does not match expected version (${JAVA_VERSION})"
			exit 1
		fi
	else
		log_warn "Unable to validate built JAR version as 'od' is not installed"
	fi
}

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
log_tool_info "01 - Fernflower"
DIST_FERNFLOWER="${DIST_DIR}/fernflower__${JAVA_VERSION}.jar"
if [ -f "${DIST_FERNFLOWER}" ]; then
	echo "[INFO] 'Fernflower' is already available"
else
	REPO_URL=https://github.com/JetBrains/intellij-community.git

	check_java_version

	TMP_DIR=/tmp/intellij
	rm -Rf "${TMP_DIR}"
	mkdir -p "${TMP_DIR}"

	pushd "${TMP_DIR}" &>/dev/null
	# Retrieve latest idea tag
	LATEST_TAG=$(git ls-remote --tags "${REPO_URL}" | grep -o "refs/tags/idea/.*" | sort -r | head -n 1 | tr -d '^{}' | cut -d "/" -f 3-)
	echo "Downloading 'Fernflower' from Intellij-Community '${LATEST_TAG}'"

	# Do not retrieve the repository
	git clone --depth=1 --branch "${LATEST_TAG}" --filter=blob:none --sparse "${REPO_URL}"
	cd intellij-community

	# Selectively checkout sub directory
	git sparse-checkout set plugins/java-decompiler/engine
	#git checkout HEAD -- plugins/java-decompiler/engine/
	cd plugins/java-decompiler/engine

	# Build Fernflower
	GRADLE_OPTS="-Dorg.gradle.daemon=false" ./gradlew assemble
	popd &>/dev/null

	check_built_java_version "${TMP_DIR}/intellij-community/plugins/java-decompiler/engine/build/classes/java/main/org/jetbrains/java/decompiler/ClassNameConstants.class"

	cp "${TMP_DIR}/intellij-community/plugins/java-decompiler/engine/build/libs/fernflower.jar" "${DIST_DIR}/fernflower__${JAVA_VERSION}.jar"
	rm -Rf "${TMP_DIR}"
fi

##############################################################################################################
# 02 CSA
##############################################################################################################
log_tool_info "02 - CSA v${CSA_VERSION}"
DIST_CSA="${DIST_DIR}/cloud-suitability-analyzer-${CSA_VERSION}.zip"
if [ -f "${DIST_CSA}" ]; then
	echo "[INFO] 'CSA' (${CSA_VERSION}) is already available"
else
	# Delete previous versions
	find "${SCRIPT_PATH}/../../dist/" -type f -iname 'cloud-suitability-analyzer-*.zip' -delete

	TMP_DIR=/tmp/cloud-suitability-analyzer
	rm -Rf "${TMP_DIR}"
	mkdir -p "${TMP_DIR}"
	pushd "${TMP_DIR}" &>/dev/null
	wget -q -O "csa-l" "https://github.com/vmware-tanzu/cloud-suitability-analyzer/releases/download/v${CSA_VERSION}/csa-l"
	wget -q -O "csa" "https://github.com/vmware-tanzu/cloud-suitability-analyzer/releases/download/v${CSA_VERSION}/csa"
	#wget -q -O "CSA-UserManual.pdf" "https://github.com/vmware-tanzu/cloud-suitability-analyzer/releases/download/v${CSA_VERSION}/CSA-UserManual.pdf"
	chmod +x csa-l csa
	cd ..
	zip -r "cloud-suitability-analyzer-${CSA_VERSION}.zip" cloud-suitability-analyzer
	popd &>/dev/null
	mv "/tmp/cloud-suitability-analyzer-${CSA_VERSION}.zip" "${DIST_DIR}"
	rm -Rf "${TMP_DIR}"
fi

# 02 CSA - Bagger build
log_tool_info "02 - CSA v${CSA_VERSION} - Bagger"
if [ -f "${DIST_DIR}/bagger__${JAVA_VERSION}.jar" ]; then
	echo "[INFO] 'Bagger' is already available"
else
	check_java_version
	echo "Compiling & packaging 'Bagger'"
	mvn -v >/dev/null 2>&1 || { echo >&2 "[ERROR] Maven is required for Bagger, but not installed."; }
	mvn -f "${DIST_DIR}/bagger" clean package assembly:single -Djava.version="${JAVA_VERSION}"	
	check_built_java_version "${DIST_DIR}/bagger/target/classes/io/pivotal//Bagger.class"
	cp "${DIST_DIR}"/bagger/target/*-with-dependencies.jar "${DIST_DIR}/bagger__${JAVA_VERSION}.jar"
fi

##############################################################################################################
# 03 Windup
##############################################################################################################
log_tool_info "03 - Windup v${WINDUP_VERSION}"
DIST_WINDUP="${DIST_DIR}/oci__windup_${WINDUP_VERSION}.img"
if [ -f "${DIST_WINDUP}" ]; then
	echo "[INFO] 'Windup' (${WINDUP_VERSION}) is already available"
else
	# 03 Windup (https://windup.github.io/downloads/)
	IMG_NAME="windup:${WINDUP_VERSION}"
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

	${MUSTACHE} "Dockerfile.windup.mo" >"Dockerfile"
	${CONTAINER_ENGINE} buildx build --platform "${DOCKER_PLATFORM}" -f "Dockerfile" -t "${IMG_NAME}" .
	# Cleanup
	rm -f "Dockerfile"
	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${IMG_NAME}" | gzip >"${DIST_WINDUP}"
fi

##############################################################################################################
# 04 IBM WAMT
##############################################################################################################
log_tool_info "04 - WAMT v${WAMT_VERSION}"
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
	IMG_NAME="wamt:${WAMT_VERSION}"
	pushd "${SCRIPT_PATH}/../../dist/containerized/wamt" &>/dev/null

	${MUSTACHE} "Dockerfile.wamt.mo" >"Dockerfile"
	${CONTAINER_ENGINE} buildx build --platform "${DOCKER_PLATFORM}" -f "Dockerfile" -t "${IMG_NAME}" .
	# Cleanup
	rm -f "Dockerfile"
	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${IMG_NAME}" | gzip >"${DIST_IBM_WAMT}"
fi

##############################################################################################################
# 05 OWASP DC
##############################################################################################################
log_tool_info "05 - OWASP DC v${OWASP_DC_VERSION}"

ODC_IMG="${DIST_DIR}/oci__owasp-dependency-check_${OWASP_DC_VERSION}.img"
if [[ -f "${ODC_IMG}" ]]; then
	echo "[INFO] 'OWASP DC' (${OWASP_DC_VERSION}) is already available"
else
	echo "[INFO] Downloading and building 'OWASP DC' (${OWASP_DC_VERSION}) ${CONTAINER_ENGINE} image"

	# Delete previous versions
	find "${DIST_DIR}" -type f -iname 'oci__owasp-dependency-check_*.img' -delete
	find "${DIST_DIR}/containerized/owasp-dependency-check" -type f -iname 'owasp-dependency-check*.zip' ! -name "owasp-dependency-check_${OWASP_DC_VERSION}.zip" -delete

	ODC_SHORT_ZIP="containerized/owasp-dependency-check/owasp-dependency-check_${OWASP_DC_VERSION}.zip"
	ODC_ZIP="${DIST_DIR}/${ODC_SHORT_ZIP}"

	simple_check_and_download "OWASP Dependency-Check" "${ODC_SHORT_ZIP}" "https://github.com/jeremylong/DependencyCheck/releases/download/v${OWASP_DC_VERSION}/dependency-check-${OWASP_DC_VERSION}-release.zip" "${OWASP_DC_VERSION}"

	# Build container image
	IMG_NAME="owasp-dependency-check:${OWASP_DC_VERSION}"
	pushd "${SCRIPT_PATH}/../../dist/containerized/owasp-dependency-check" &>/dev/null

	if [[ "${DOCKER_ARCH}" == "arm64" ]]; then
		export DOTNET_RUNTIME="${DOTNET_RUNTIME_TAG}-${DOCKER_ARCH}v8"
	else
		export DOTNET_RUNTIME="${DOTNET_RUNTIME_TAG}-${DOCKER_ARCH}"
	fi

	${MUSTACHE} "Dockerfile.owasp-dc.mo" >"Dockerfile"
	${CONTAINER_ENGINE} buildx build --platform "${DOCKER_PLATFORM}" -f "Dockerfile" -t "${IMG_NAME}" .

	# Cleanup
	rm -f "Dockerfile"
	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${IMG_NAME}" | gzip >"${ODC_IMG}"
fi

simple_check_and_download "Nist Data Mirror" "containerized/owasp-dependency-check/nist-data-mirror.jar" "https://github.com/stevespringett/nist-data-mirror/releases/download/nist-data-mirror-${NIST_MIRROR_VERSION}/nist-data-mirror.jar" "${NIST_MIRROR_VERSION}"

if [[ "${UPDATE_VULN_DBS}" == "true" ]]; then
	DATA_DIR="${DIST_DIR}/owasp_data"
	mkdir -p "${DATA_DIR}/cache" "${DATA_DIR}/nvdcache"

	# Download and cache locally the NVD and RetireJS databases for the OWASP analysis
	echo "[INFO] Updating local RetireJS cache ..."
	wget -q -O "${DATA_DIR}/jsrepository.json" "https://raw.githubusercontent.com/Retirejs/retire.js/master/repository/jsrepository.json"

	echo "[INFO] Updating local NVD cache ..."
	set +e
	java -jar "${DIST_DIR}/containerized/owasp-dependency-check/nist-data-mirror.jar" "${DATA_DIR}/nvdcache"
	set -e
fi

##############################################################################################################
# 06 ScanCode Toolkit
##############################################################################################################
log_tool_info "06 - ScanCode v${SCANCODE_VERSION}"
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
	#sed -i '' -Ee 's/FROM python(.*)/FROM arm32v7\/python\1/g' Dockerfile
	rm scancode
	cp "${SCRIPT_PATH}/../../dist/containerized/scancode-toolkit/scancode" .
	chmod +x scancode
	${CONTAINER_ENGINE} buildx build --platform "${DOCKER_PLATFORM}" -t scancode-toolkit .
	popd &>/dev/null

	# Cleanup
	rm -Rf "${TMP_SCANCODE_BUILD_DIR}"
	${CONTAINER_ENGINE} image save scancode-toolkit:latest | gzip >"${SC_IMG}"
fi

##############################################################################################################
# 07 PMD
##############################################################################################################
log_tool_info "07 - PMD v${PMD_VERSION}"
simple_check_and_download "PMD" "pmd-bin-${PMD_VERSION}.zip" "https://github.com/pmd/pmd/releases/download/pmd_releases%2F${PMD_VERSION}/pmd-bin-${PMD_VERSION}.zip" "${PMD_VERSION}"

# Libraries to fix issues with PMD
simple_check_and_download "PMD_LIB__commons-compiler" "pmd-missing-commons-compiler-3.1.7.jar" "https://repo1.maven.org/maven2/org/codehaus/janino/commons-compiler/3.1.7/commons-compiler-3.1.7.jar" "3.1.7"
simple_check_and_download "PMD_LIB__jakarta.activation" "pmd-missing-jakarta.activation-2.0.1.jar" "https://repo1.maven.org/maven2/com/sun/activation/jakarta.activation/2.0.1/jakarta.activation-2.0.1.jar" "2.0.1"
simple_check_and_download "PMD_LIB__jakarta.activation-api" "pmd-missing-jakarta.activation-api-1.2.2.jar" "https://repo1.maven.org/maven2/jakarta/activation/jakarta.activation-api/1.2.2/jakarta.activation-api-1.2.2.jar" "1.2.2"
simple_check_and_download "PMD_LIB__jakarta.mail-api" "pmd-missing-jakarta.mail-api-1.6.7.jar" "https://repo1.maven.org/maven2/jakarta/mail/jakarta.mail-api/1.6.7/jakarta.mail-api-1.6.7.jar" "1.6.7"
simple_check_and_download "PMD_LIB__janino" "pmd-missing-janino-3.1.7.jar" "https://repo1.maven.org/maven2/org/codehaus/janino/janino/3.1.7/janino-3.1.7.jar" "3.1.7"
simple_check_and_download "PMD_LIB__mailapi" "pmd-missing-mailapi-2.0.1.jar" "https://repo1.maven.org/maven2/com/sun/mail/mailapi/2.0.1/mailapi-2.0.1.jar" "2.0.1"

# Additional security rules
log_tool_info "07 - PMD v${PMD_VERSION} - GDS rules"
simple_check_and_download "PMD_GDS" "pmd-gds-${PMD_GDS_VERSION}.jar" "https://github.com/albfernandez/GDS-PMD-Security-Rules/releases/download/v.${PMD_GDS_VERSION}/pmd-gds-${PMD_GDS_VERSION}.jar" "${PMD_GDS_VERSION}"

##############################################################################################################
# 08 Linguist
##############################################################################################################
log_tool_info "08 - Linguist v${LINGUIST_VERSION}"
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
	${CONTAINER_ENGINE} buildx build --platform "${DOCKER_PLATFORM}" -t "crazymax/linguist:${LINGUIST_VERSION}" .
	popd &>/dev/null
	${CONTAINER_ENGINE} image save "crazymax/linguist:${LINGUIST_VERSION}" | gzip >"${DIST_DIR}/${LINGUIST_IMG}"
	rm -Rf /tmp/linguist
fi

##############################################################################################################
# 08 CLOC
##############################################################################################################
log_tool_info "08 - CLOC v${CLOC_VERSION}"
simple_check_and_download "CLOC" "cloc-${CLOC_VERSION}.tar.gz" "https://github.com/AlDanial/cloc/releases/download/v${CLOC_VERSION}/cloc-${CLOC_VERSION}.tar.gz" "${CLOC_VERSION}"

##############################################################################################################
# 09 FindSecBugs
##############################################################################################################
log_tool_info "09 - FindSecBugs v${FSB_VERSION}"
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
	IMG_NAME="findsecbugs:${FSB_VERSION}"
	pushd "${SCRIPT_PATH}/../../dist/containerized/findsecbugs" &>/dev/null
	${MUSTACHE} "Dockerfile.fsb.mo" >"Dockerfile"
	${CONTAINER_ENGINE} buildx build --platform "${DOCKER_PLATFORM}" -f "Dockerfile" -t "${IMG_NAME}" .
	# Cleanup
	rm -f "Dockerfile"
	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${IMG_NAME}" | gzip >"${FSB_DIST}"
fi

##############################################################################################################
# 10 Microsoft Application Inspector (MAI)
##############################################################################################################
log_tool_info "10 - MAI v${MAI_VERSION}"
DIST_MAI="${DIST_DIR}/oci__mai_${MAI_VERSION}.img"
if [ -f "${DIST_MAI}" ]; then
	echo "[INFO] 'MAI' (${DIST_MAI}) is already available"
else
	MAI_DIR="${DIST_DIR}/containerized/mai"
	MAI_ZIP="${MAI_DIR}/ApplicationInspector_netcoreapp_${MAI_VERSION}.zip"

	# Delete previous versions
	find "${SCRIPT_PATH}/../../dist/containerized/mai/" -type f -iname 'ApplicationInspector_netcoreapp_*.zip' ! -name ApplicationInspector_netcoreapp_${MAI_VERSION}.zip -delete
	find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__mai_*.img' -delete

	simple_check_and_download "Microsoft Application Inspector" "containerized/mai/ApplicationInspector_netcoreapp_${MAI_VERSION}.zip" "https://github.com/microsoft/ApplicationInspector/releases/download/v${MAI_VERSION}/ApplicationInspector_netcoreapp_${MAI_VERSION}.zip" "${MAI_VERSION}"

	# Build container image
	IMG_NAME="mai:${MAI_VERSION}"
	pushd "${SCRIPT_PATH}/../../dist/containerized/mai" &>/dev/null

	if [[ "${DOCKER_ARCH}" == "arm64" ]]; then
		export DOTNET_RUNTIME="${DOTNET_RUNTIME_TAG}-${DOCKER_ARCH}v8"
	else
		export DOTNET_RUNTIME="${DOTNET_RUNTIME_TAG}-${DOCKER_ARCH}"
	fi
	${MUSTACHE} "Dockerfile.mai.mo" >"Dockerfile"
	${CONTAINER_ENGINE} buildx build --platform "${DOCKER_PLATFORM}" -f "Dockerfile" -t "${IMG_NAME}" .
	# Cleanup
	rm -f "Dockerfile"
	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${IMG_NAME}" | gzip >"${DIST_MAI}"
fi

##############################################################################################################
# 11 SAST-Scan
##############################################################################################################
# Loading the latest linguist container image (only for amd64)
if [[ "${ARCH}" == "x86_64" ]]; then
	log_tool_info "11 - SAST-Scan v${SLSCAN_VERSION}"
	find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__sast-scan_*.img' ! -name oci__sast-scan_${SLSCAN_VERSION}.img -delete
	download_container_image 'SAST-Scan (slscan)' "latest" "shiftleft/sast-scan" "oci__sast-scan_${SLSCAN_VERSION}.img"
fi

##############################################################################################################
# 12 Insider
##############################################################################################################
# Load the latest Insider container image
log_tool_info "12 - Insider v${INSIDER_VERSION}"
find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__insider_*.img' ! -name oci__insider_${INSIDER_VERSION}.img -delete
download_container_image 'Insider' "latest" "insidersec/insider" "oci__insider_${INSIDER_VERSION}.img" "linux/amd64"

##############################################################################################################
# 13 Grype
##############################################################################################################
# Load the correct Grype container image
log_tool_info "13 - Grype v${GRYPE_VERSION}"
find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__grype_*.img' ! -name oci__grype_${GRYPE_VERSION}.img -delete
download_container_image 'Grype' "v${GRYPE_VERSION}" "anchore/grype" "oci__grype_${GRYPE_VERSION}.img"

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
log_tool_info "13 - Syft v${SYFT_VERSION}"
find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__syft_*.img' ! -name oci__syft_${SYFT_VERSION}.img -delete
download_container_image 'Syft' "v${SYFT_VERSION}" "anchore/syft" "oci__syft_${SYFT_VERSION}.img"

##############################################################################################################
# 14 Trivy
##############################################################################################################
# Load the correct Trivy container image
log_tool_info "14 - Trivy v${TRIVY_VERSION}"
DIST_TRIVY="${DIST_DIR}/oci__trivy_${TRIVY_VERSION}.img"
if [[ "${UPDATE_VULN_DBS}" == "true" ]]; then
	# Remove current image to force an update of the cache
	find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__trivy_*.img' -delete
	remove_container_images "trivy"
fi
if [ -f "${DIST_TRIVY}" ]; then
	echo "[INFO] 'Trivy' (${DIST_TRIVY}) is already available"
else
	find "${SCRIPT_PATH}/../../dist/" -type f -iname 'oci__trivy_*.img' ! -name oci__trivy_${TRIVY_VERSION}.img -delete

	# Build container image including cache as it otherwise does not work in an airgapped environmment with podman
	## https://aquasecurity.github.io/trivy/v0.43/docs/advanced/air-gap/
	IMG_NAME="trivy:${TRIVY_VERSION}"
	pushd "${SCRIPT_PATH}/../../dist/containerized/trivy" &>/dev/null

	${MUSTACHE} "Dockerfile.trivy.mo" >"Dockerfile"
	${CONTAINER_ENGINE} buildx build --platform "${DOCKER_PLATFORM}" -f "Dockerfile" -t "${IMG_NAME}" .
	# Cleanup
	rm -f "Dockerfile"
	popd &>/dev/null

	# Save
	${CONTAINER_ENGINE} image save "${IMG_NAME}" | gzip >"${DIST_TRIVY}"
fi

##############################################################################################################
# 99 Reports - Update imported static content
##############################################################################################################
log_tool_info "99 - Static content"

JS_DIR="${DIST_DIR}/templating/static/js"
mkdir -p "${JS_DIR}"

#set -x
find "${SCRIPT_PATH}/../../dist/templating/static/js" -type f -iname 'd3.v*.min.js' ! -name d3.v4.min.js ! -name d3.v${D3_VERSION}.min.js -delete
simple_check_and_download "JavaScript - D3.js" "templating/static/js/d3.v4.min.js" 'https://unpkg.com/d3@4.13.0/build/d3.min.js' "4.13.0"
simple_check_and_download "JavaScript - D3.js" "templating/static/js/d3.v${D3_VERSION}.min.js" "https://unpkg.com/d3@${D3_VERSION}/dist/d3.min.js" "${D3_VERSION}"

find "${SCRIPT_PATH}/../../dist/templating/static/js" -type f -iname 'jquery-*.min.js' ! -name jquery-${JQUERY_VERSION}.min.js -delete
simple_check_and_download "JavaScript - jQuery" "templating/static/js/jquery-${JQUERY_VERSION}.min.js" "https://unpkg.com/jquery@${JQUERY_VERSION}/dist/jquery.min.js" "${JQUERY_VERSION}"

if [ -f "${JS_DIR}/timelines-chart-${TIMELINES_CHART_VERSION}.min.js" ]; then
	echo "[INFO] 'JavaScript - Timelines Chart' (${TIMELINES_CHART_VERSION}) is already available"
else
	find "${SCRIPT_PATH}/../../dist/templating/static/js" -type d -iname 'timelines-chart*.min.js' -exec rm -rf {} \;
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
	BOOTSTRAP_ZIP="${DIST_STATIC}/bootstrap-${BOOTSTRAP_VERSION}-dist.zip"

	mkdir -p "${DIST_STATIC}"
	# Delete previous folder and distributions
	find "${SCRIPT_PATH}/../../dist/templating/static" -type d -iname 'bootstrap-*-dist' -exec rm -rf {} \;
	find "${SCRIPT_PATH}/../../dist/templating/static" -type f -iname 'bootstrap-*-dist.zip' ! -name bootstrap-${BOOTSTRAP_VERSION}-dist.zip -delete

	simple_check_and_download "Bootstrap" "templating/static/bootstrap-${BOOTSTRAP_VERSION}-dist.zip" "https://github.com/twbs/bootstrap/releases/download/v${BOOTSTRAP_VERSION}/bootstrap-${BOOTSTRAP_VERSION}-dist.zip" "${BOOTSTRAP_VERSION}"

	pushd "${SCRIPT_PATH}/../../dist/templating/static" &>/dev/null

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
	BOOTSTRAP_ICONS_ZIP="${DIST_STATIC}/bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}.zip"
	mkdir -p "${DIST_STATIC}/css" "${DIST_STATIC}/fonts"
	find "${SCRIPT_PATH}/../../dist/templating/static/css" -type f -iname 'bootstrap-icons-*.css' -delete
	find "${SCRIPT_PATH}/../../dist/templating/static/fonts" -type f -iname 'bootstrap-icons.*' -delete
	simple_check_and_download "Bootstrap Icons" "templating/static/bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}.zip" "https://github.com/twbs/icons/releases/download/v${BOOTSTRAP_ICONS_VERSION}/bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}.zip" "${BOOTSTRAP_ICONS_VERSION}"
	pushd "${SCRIPT_PATH}/../../dist/templating/static" &>/dev/null
	unzip bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}.zip &>/dev/null
	cp -f bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}/font/bootstrap-icons.css css/bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}.css
	cp -f bootstrap-icons-${BOOTSTRAP_ICONS_VERSION}/font/fonts/* fonts/.
	rm -Rf bootstrap-icons-*
	popd &>/dev/null
fi

##############################################################################################################
# Images, Logos, Favicon, Fonts, Scripts
##############################################################################################################

mkdir -p "${DIST_STATIC}/img/"
simple_check_and_download "Favicon - VMware" "templating/static/img/favicon.ico" 'https://www.vmware.com/favicon.ico' "latest"

simple_check_and_download "Logo - CSA" "templating/static/img/csa.svg" 'https://raw.githubusercontent.com/vmware-tanzu/cloud-suitability-analyzer/master/csa-app/frontend/src/assets/csa-icon.svg' "latest"
simple_check_and_download "Logo - FSB" "templating/static/img/fsb.png" 'https://avatars.githubusercontent.com/u/16162781?s=200&v=4' "latest"

if [ -f "${DIST_STATIC}/img/github.svg" ]; then
	echo "[INFO] 'Logo - GitHub' (latest) is already available"
else
	simple_check_and_download "Logo - GitHub" "templating/static/img/github-mark.zip" 'https://github.githubassets.com/images/modules/logos_page/github-mark.zip' "latest"
	pushd "${DIST_STATIC}/img/" &>/dev/null
	unzip github-mark.zip &>/dev/null
	mv github-mark/github-mark.svg github.svg
	rm -Rf github-mark github-mark.zip
	popd &>/dev/null
fi

simple_check_and_download "Logo - VMware" "templating/static/img/vmware.svg" 'https://www.vmware.com/content/dam/digitalmarketing/vmware/en/images/company/vmware-logo-grey.svg' "latest"
simple_check_and_download "Logo - Grype" "templating/static/img/grype.png" 'https://anchore.com/wp-content/uploads/2021/11/image-111.png' "latest"
simple_check_and_download "Logo - IBM WAMT" "templating/static/img/ibm.jpg" 'https://avatars.githubusercontent.com/u/28316667?s=200&v=4' "latest"
simple_check_and_download "Logo - Insider" "templating/static/img/insider.png" 'https://avatars.githubusercontent.com/u/53912687?s=200&v=4' "latest"
simple_check_and_download "Logo - Microsoft" "templating/static/img/microsoft.png" 'https://avatars.githubusercontent.com/u/6154722?s=200&v=4' "latest"
simple_check_and_download "Logo - OWASP" "templating/static/img/owasp.svg" 'https://owasp.org/assets/images/logo.svg' "latest"
simple_check_and_download "Logo - PMD" "templating/static/img/pmd.png" 'https://avatars.githubusercontent.com/u/1958157?s=200&v=4' "latest"
simple_check_and_download "Logo - Scan" "templating/static/img/scan-light.png" 'https://avatars.githubusercontent.com/u/21226431?s=200&v=4' "latest"
simple_check_and_download "Logo - ScanCode" "templating/static/img/scancode.png" 'https://avatars.githubusercontent.com/u/10789967?s=200&v=4' "latest"
simple_check_and_download "Logo - Trivy" "templating/static/img/trivy.svg" 'https://raw.githubusercontent.com/aquasecurity/trivy-docker-extension/main/trivy.svg' "latest"
simple_check_and_download "Logo - Windup" "templating/static/img/windup.png" 'https://avatars.githubusercontent.com/u/4266383?s=200&v=4' "latest"

# https://devicon.dev/
simple_check_and_download "Icon - C#" "templating/static/img/icon-csharp.svg" 'https://raw.githubusercontent.com/devicons/devicon/master/icons/csharp/csharp-original.svg' "latest"
simple_check_and_download "Icon - Java" "templating/static/img/icon-java.svg" 'https://raw.githubusercontent.com/devicons/devicon/master/icons/java/java-original.svg' "latest"
simple_check_and_download "Icon - JavaScript" "templating/static/img/icon-javascript.svg" 'https://raw.githubusercontent.com/devicons/devicon/master/icons/javascript/javascript-original.svg' "latest"
simple_check_and_download "Icon - Python" "templating/static/img/icon-python.svg" 'https://raw.githubusercontent.com/devicons/devicon/master/icons/python/python-original.svg' "latest"
# https://icons.getbootstrap.com/
simple_check_and_download "Icon - Other" "templating/static/img/icon-other.svg" 'https://icons.getbootstrap.com/assets/icons/patch-question-fill.svg' "latest"

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

rm -Rf "${DIST_BIN}"
