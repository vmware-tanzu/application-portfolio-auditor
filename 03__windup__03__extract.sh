#!/usr/bin/env bash
# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Extract level-of-effort (LoE) scores from the reports generated by ...
#   "Windup" - https://github.com/windup/windup
##############################################################################################################

export XSL_FILE LOG_FILE VERSION

SEPARATOR=","
STEP=$(get_step)
LOG_FILE="${REPORTS_DIR}/${STEP}__WINDUP.log"
VERSION="${WINDUP_VERSION}"

function check_missing_apps() {
	APP_DIR_INCOMING=${1}
	GROUP=$(basename "${APP_DIR_INCOMING}")
	OUT_GROUP="${REPORTS_DIR}/${STEP}__WINDUP__${GROUP}"
	RESULT_SHELL_FILE="${OUT_GROUP}__results_extracted_shell.csv"
	MISSING_FILE="${OUT_GROUP}__results_missing.csv"
	RESULT_FILE="${OUT_GROUP}__results_extracted.csv"
	RESULT_REPORT_MAP="${OUT_GROUP}__report_map.js"
	LIST_JAVA_BIN="${REPORTS_DIR}/list__${GROUP}__java-bin.txt"
	LIST_JAVA_SRC_INIT="${REPORTS_DIR}/list__${GROUP}__java-src-init.txt"

	log_extract_message "group '${GROUP}'"

	rm -f "${MISSING_FILE}" "${RESULT_REPORT_MAP}"

	# Add missing entries
	while read -r FILE; do
		APP="$(basename "${FILE}")"
		if [[ -f "${RESULT_SHELL_FILE}" ]]; then
			if ! grep -q "${APP}${SEPARATOR}" "${RESULT_SHELL_FILE}"; then
				if ! grep -q "${APP}_SRC.jar${SEPARATOR}" "${RESULT_SHELL_FILE}"; then
					echo "${APP}${SEPARATOR}n/a" >>"${MISSING_FILE}"
				fi
			fi
		else
			echo "${APP}${SEPARATOR}n/a" >>"${MISSING_FILE}"
		fi
	done <"${REPORTS_DIR}/list__${GROUP}__all_apps.txt"

	# Merge results with missing entries
	touch "${RESULT_SHELL_FILE}" "${MISSING_FILE}"
	cat "${RESULT_SHELL_FILE}" "${MISSING_FILE}" | sort | uniq >"${RESULT_FILE}"

	# Cleanup
	rm -f "${RESULT_SHELL_FILE}" "${MISSING_FILE}"

	stream_edit 's/_SRC\.jar//g' "${RESULT_FILE}"

	# Adding the header
	{
		echo "Applications${SEPARATOR}WINDUP story points"
		cat "${RESULT_FILE}"
	} >"${RESULT_FILE}.tmp"
	mv "${RESULT_FILE}.tmp" "${RESULT_FILE}"

	# Generate HTML report map
	WINDUP_REPORT_DIR="${REPORTS_DIR}/${STEP}__WINDUP__${GROUP}/reports/"
	if [[ ! -d "${WINDUP_REPORT_DIR}" ]]; then
		if [[ -s "${LIST_JAVA_BIN}" || -s "${LIST_JAVA_SRC_INIT}" ]]; then
			log_console_error "WINDUP result folder does not exist: ${WINDUP_REPORT_DIR}"
		fi
	fi

	# Building the result report map
	RESULT_REPORT_MAP_TMP="${RESULT_REPORT_MAP}.tmp"
	rm -f "${RESULT_REPORT_MAP_TMP}"
	touch "${RESULT_REPORT_MAP_TMP}"

	while read -r FILE; do
		APP=$(basename "${FILE}")
		APP_WINDUP_NAME="${APP}"
		# Update searched name for Java source code apps
		if (grep -q -i "${FILE}" "${LIST_JAVA_SRC_INIT}"); then
			APP_WINDUP_NAME="${APP}_SRC.jar"
		fi
		REPORT_FULL_NAME=""
		if [[ -d "${WINDUP_REPORT_DIR}" ]]; then
			set +e
			REPORT_FULL_NAME=$(find "${WINDUP_REPORT_DIR}" -type f -name 'ApplicationDetails_*.html' -exec grep -l "<div class=\"path\">${APP_WINDUP_NAME}</div>" {} + | head -n 1)
			set -e
		fi
		REPORT_NAME="$(basename "${REPORT_FULL_NAME}")"
		echo "  ['${APP}', '${REPORT_NAME}']," >>"${RESULT_REPORT_MAP_TMP}"
	done <"${REPORTS_DIR}/list__${GROUP}__all_apps.txt"

	{
		echo "let reportMap = new Map(["
		cat "${RESULT_REPORT_MAP_TMP}"
		echo "])"
	} >"${RESULT_REPORT_MAP}"

	rm -f "${RESULT_REPORT_MAP_TMP}"
}

function main() {

	XSL_FILE="${CURRENT_DIR}/conf/Windup/process_WINDUP.xsl"

	#set -x

	while read -r FILE; do
		REGEX="s|${STEP}__WINDUP__(.*)|\1|g"
		GROUP=$(basename "$(dirname "${FILE}")" | sed -Ee "${REGEX}")
		GROUP_DIR=${REPORTS_DIR}/${STEP}__WINDUP__${GROUP}
		RESULT_FILE="${GROUP_DIR}__results_extracted_shell.csv"

		# "2>/dev/null" hides all parsing errors from the console
		xmllint --html --xmlout "${FILE}" 2>/dev/null | xsltproc --stringparam separator "${SEPARATOR}" "${XSL_FILE}" - >>"${RESULT_FILE}"

		# Removing dots in numbers
		awk 'BEGIN {OFS=FS=","} {$1;gsub(/\./,"",$2)}1' "${RESULT_FILE}" >"${RESULT_FILE}.tmp"
		# Removing ? in numbers
		awk 'BEGIN {OFS=FS=","} {$1;gsub(/\?/,"",$2)}1' "${RESULT_FILE}.tmp" >"${RESULT_FILE}"
		rm -f "${RESULT_FILE}.tmp"

		# Cleaning up the generated windup report
		if [[ "${IS_MAC}" == "true" ]]; then
			## Removing trackers slowing down pages
			find "${GROUP_DIR}" -maxdepth 2 -name "*.html" -type f -exec sed -i '' '/<ul class="nav navbar-nav navbar-right">/,/<\/ul>/d' {} +
			## Cleanup title
			find "${GROUP_DIR}" -maxdepth 2 -name "*.html" -type f -exec sed -i '' '/<strong class="wu-navbar-header">Windup<\/strong>/d' {} +
			find "${GROUP_DIR}" -maxdepth 2 -name "*.html" -type f -exec sed -i '' 's/<img align="right" class="wu-navbar-header" src="\(.*\/\)brand-horizontal.png" \/>/<img align="left" class="wu-navbar-header" src="\1brand-horizontal.png" style="padding-left: 12px;"\/>/g' {} +
		else
			## Removing trackers slowing down pages
			find "${GROUP_DIR}" -maxdepth 2 -name "*.html" -type f -exec sed -i '/<ul class="nav navbar-nav navbar-right">/,/<\/ul>/d' {} +
			## Cleanup title
			find "${GROUP_DIR}" -maxdepth 2 -name "*.html" -type f -exec sed -i '/<strong class="wu-navbar-header">Windup<\/strong>/d' {} +
			find "${GROUP_DIR}" -maxdepth 2 -name "*.html" -type f -exec sed -i 's/<img align="right" class="wu-navbar-header" src="\(.*\/\)brand-horizontal.png" \/>/<img align="left" class="wu-navbar-header" src="\1brand-horizontal.png" style="padding-left: 12px;"\/>/g' {} +
		fi

	done < <(find "${REPORTS_DIR}" -mindepth 2 -maxdepth 2 -type f -name 'index.html' | grep "__WINDUP")

	# Check and add missing entries
	for_each_group check_missing_apps

}

main
