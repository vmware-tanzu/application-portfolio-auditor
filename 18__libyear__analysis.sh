#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all applications in ${APP_DIR_IN} grouped in sub-folders using "Libyear".
#
# "Libyear" is a simple measure of software dependency freshness. It is a single number telling you how up-to-date your dependencies are.
##############################################################################################################

# ----- Please adjust

## If necessary, adjust the "cat <<EOF" section underneath to point to you maven repository in use

# ------ Do not modify
VERSION=${TOOL_VERSION}
STEP=$(get_step)

export OUT_DIR_LIBYEAR="${REPORTS_DIR}/${STEP}__LIBYEAR"
export LOG_FILE="${OUT_DIR_LIBYEAR}.log"
APP_LIST="${REPORTS_DIR}/00__Weave/list__all_init_apps.txt"
LIST_JAVA_BIN="${REPORTS_DIR}/00__Weave/list__java-bin.txt"
RESULT_SUMMARY_LIBYEAR_CSV="${OUT_DIR_LIBYEAR}/_results__quality__libyear.csv"
SEPARATOR=","

function compute_libyears_behind() {
	local MVN_LOG=${1}
	local POM_XML=${2}
	rm -f "${MVN_LOG}"
	mvn -T 4 io.github.mfoo:libyear-maven-plugin:${LIBYEAR_VERSION}:analyze -f "${POM_XML}" -l "${MVN_LOG}"
}

function compute() {
	local MVN_LOG=${1}
	local POM_XML=${2}
	local RETRY=${3}
	local SLEEP_TIME=${4}
	if [[ -f "${MVN_LOG}" ]]; then
		ERROR_COUNT=$(grep -o '\[ERROR\] Failed to fetch release date for [^ ]*' "${MVN_LOG}" | sort | uniq | wc -l | tr -d ' \t')
		if [[ ${ERROR_COUNT} -gt 0 ]]; then
			if [[ "${RETRY}" == "last" ]]; then
				log_console_error "${ERROR_COUNT} errors while fetching release dates."
			else
				log_console_warning "${ERROR_COUNT} errors while fetching release dates. Retrying ${RETRY}"
				sleep "${SLEEP_TIME}"
				compute_libyears_behind "${MVN_LOG}" "${POM_XML}"
			fi
		fi
	else
		compute_libyears_behind "${MVN_LOG}" "${POM_XML}"
	fi
}

# Analyze all applications present in the ${APP_GROUP_DIR} directory.
function analyze() {
	if [[ -s "${APP_LIST}" ]]; then
		echo "Applications${SEPARATOR}Libyears behind" >"${RESULT_SUMMARY_LIBYEAR_CSV}"
		while read -r APP; do
			APP_NAME=$(basename "${APP}")
			APP_FOLDER=$(dirname "${APP}")
			log_analysis_message "app '${APP_NAME}'"

			local LIBYEAR_COUNT='n/a'

			if (grep -q -i "${APP}" "${LIST_JAVA_BIN}"); then
				# Generate / copy Syft file
				APP_NAME_SHORT="${APP_NAME}"
				if [[ "${APP_NAME}" == *\.zip ]]; then
					APP_NAME_SHORT="${APP_NAME%.*}"
				fi

				RESULT_JSON="${APP_NAME_SHORT}_syft_spdx.json"
				OUT_DIR_ARCHEO="${REPORTS_DIR}/16__ARCHEO"
				RESULT_SYFT_JSON="${OUT_DIR_LIBYEAR}/${RESULT_JSON}"

				if [[ -f "${OUT_DIR_ARCHEO}/${RESULT_JSON}" ]]; then
					## Copy existing -Syft- results
					log_analysis_message "Reusing existing Syft results ('${OUT_DIR_ARCHEO}/${RESULT_JSON}')"
					cp -fp "${OUT_DIR_ARCHEO}/${RESULT_JSON}" "${RESULT_SYFT_JSON}"
				else
					## Run -Syft- to generate SBOM
					${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} \
						-v "${APP_FOLDER}:/src" -v "${OUT_DIR_LIBYEAR}:/out" \
						-e SYFT_CHECK_FOR_APP_UPDATE=false \
						"${CONTAINER_IMAGE_NAME_SYFT}" \
						"file:/src/${APP_NAME}" -o "spdx-json=/out/${RESULT_JSON}" 2>>"${LOG_FILE}"
				fi

				if [[ -f "${RESULT_SYFT_JSON}" ]]; then

					LIBYEAR_OUTPUT="${OUT_DIR_LIBYEAR}/${APP_NAME}_libyear_findings.csv"
					APP_FINDINGS_STATS="${OUT_DIR_LIBYEAR}/${APP_NAME}_libyear_findings.stats"
					POM_XML="${OUT_DIR_LIBYEAR}/${APP_NAME}_libyear.pom.xml"
					LIBYEAR_TMP="${OUT_DIR_LIBYEAR}/${APP_NAME}_libyear.tmp"
					MVN_LOG="${OUT_DIR_LIBYEAR}/${APP_NAME}_mvn.log"

					# Extract list of libraries
					set +e
					jq -r ' .packages[] | select(.externalRefs) .externalRefs[] | select(.referenceCategory == "PACKAGE-MANAGER") | .referenceLocator' "${RESULT_SYFT_JSON}" | grep "^pkg:maven/" | sort | uniq >"${LIBYEAR_TMP}"

					log_console_info "$(count_lines ${LIBYEAR_TMP}) libraries found (Java)"

					if [[ -s "${LIBYEAR_TMP}" ]]; then

						# Generate pom.xml containing all detected libraries as dependencies
						stream_edit 's|pkg:maven/|\t\t<dependency><groupId>|g' "${LIBYEAR_TMP}"
						stream_edit 's|/|</groupId><artifactId>|g' "${LIBYEAR_TMP}"
						stream_edit 's|@|</artifactId><version>|g' "${LIBYEAR_TMP}"
						stream_edit 's|$|</version></dependency>|g' "${LIBYEAR_TMP}"

						{
							cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
	<modelVersion>4.0.0</modelVersion>
	<groupId>org.auditor</groupId>
	<artifactId>libyear-scan</artifactId>
	<version>0.0.1</version>
	<name>Libyear Scan</name>

    <repositories>
        <!-- Repository 1: Maven Central -->
        <repository>
            <id>maven-central</id>
			<name>Maven Central</name>
            <url>https://repo.maven.apache.org/maven2/</url>
			<releases>
				<enabled>true</enabled>
			</releases>
			<snapshots>
				<enabled>true</enabled>
			</snapshots>
        </repository>

        <!-- Repository 2: GCS Mirror (https://storage-download.googleapis.com/maven-central/index.html) -->
		<repository>
			<id>google-maven-central</id>
			<name>GCS Maven Central mirror EU</name>
			<url>https://maven-central-eu.storage-download.googleapis.com/maven2/</url>
			<releases>
				<enabled>true</enabled>
			</releases>
			<snapshots>
				<enabled>true</enabled>
			</snapshots>
		</repository>

        <!-- Add more repositories as needed -->
    </repositories>
	<dependencies>
EOF
							# Removing packages without version
							grep '<version>' "${LIBYEAR_TMP}"

							cat <<EOF
	</dependencies>
</project>
EOF
						} >"${POM_XML}"

						compute "${MVN_LOG}" "${POM_XML}" '' ''
						compute "${MVN_LOG}" "${POM_XML}" 'once' '10'
						compute "${MVN_LOG}" "${POM_XML}" 'twice' '30'
						compute "${MVN_LOG}" "${POM_XML}" 'thrice' '60'
						compute "${MVN_LOG}" "${POM_XML}" 'last' ''

						echo "Library${SEPARATOR}Libyears behind" >"${LIBYEAR_OUTPUT}"
						awk '/The following dependencies in Dependencies have newer versions:/,/^$/' "${MVN_LOG}" | grep '\[INFO\]   ' | sed -e 's|\[INFO\][ ]*||g' | tr -s '\n' ';' | sed -e 's|\.[\.]*||g' | sed -e 's|libyears;|\n|g' | tr -s ',' '.' | sed -e 's|  |'"${SEPARATOR}"'|g' | sed -e 's| ||g' | tr -s ';' "${SEPARATOR}" >>"${LIBYEAR_OUTPUT}"

						# Extract results
						LIBYEARS=$(grep "behind" "${MVN_LOG}" | awk -F "This module is | libyears behind" '{print $2}' | tr -s ',' '.')

						LIBS_COUNT=$(count_lines "${LIBYEAR_TMP}")

						if [[ ${LIBS_COUNT} -gt 0 && -n "${LIBYEARS}" && "${LIBYEARS}" != "0" ]]; then
							if [[ -n "$(command -v bc)" ]]; then
								AVG_LIBYEAR_PER_LIB=$(echo "scale=2; $LIBYEARS / $LIBS_COUNT" | bc -l | awk '{printf "%.2f\n", $0}')
							else
								AVG_LIBYEAR_PER_LIB="n/a"
							fi
						else
							AVG_LIBYEAR_PER_LIB=0
						fi
						# Stats for single application HTML result file
						{
							echo "LIBYEAR__TOTAL=${LIBYEARS}"
							echo "LIBYEAR__LIBS_COUNT=${LIBS_COUNT}"
							echo "LIBYEAR__AVG_LIBYEAR_PER_LIB=${AVG_LIBYEAR_PER_LIB}"
						} >"${APP_FINDINGS_STATS}"
						set -e

						if [[ -z "${LIBYEARS}" ]]; then
							LIBYEAR_COUNT=0
						else
							LIBYEAR_COUNT="${LIBYEARS}"
						fi
					else
						LIBYEAR_COUNT=0
					fi
					rm -f "${LIBYEAR_TMP}"
				else
					log_console_error "Missing Syft result file: '${RESULT_SYFT_JSON}'"
				fi

			fi

			echo "${APP_NAME}${SEPARATOR}${LIBYEAR_COUNT}" >>"${RESULT_SUMMARY_LIBYEAR_CSV}"
		done <"${APP_LIST}"
	fi
	log_console_success "Open this directory for the results: ${OUT_DIR_LIBYEAR}"
}

function main() {
	log_tool_info "Syft v${SYFT_VERSION}"
	log_tool_info "Libyear v${VERSION}"

	if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_SYFT}") ]]; then
		check_debug_mode
		mkdir -p "${OUT_DIR_LIBYEAR}"
		analyze
	else
		log_console_error "Archeo analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_SYFT}'"
	fi
}

main
