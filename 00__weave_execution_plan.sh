#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Identify application types and generate tool execution plans.
#
# This script identifies the type of each applications and generate lists of applications used by the analysis tools.
#
# LIST_ALL: list of all apps
#  -> used by 02__csa__02__extract.sh
#  -> used by 03__windup__03__extract.sh
#  -> used by 04__wamt__02__extract.sh
#  -> used by 08__linguist_and_cloc__01__analysis.sh
#  -> used by 09__findsecbugs__02__extract.sh
#  -> used by 10__mai__analysis.sh
#
# LIST_ALL_INIT: list of all initial apps
#  -> used by 13__grype__01__anaylsis.sh
#  -> used by 13__grype__02__extract.sh
#  -> used by 14__trivy__01__anaylsis.sh
#  -> used by 14__trivy__02__extract.sh
#
# LIST_JAVA_BIN: list of binary Java applications
#  -> used by 01__fernflower_decompile.sh
#  -> used by 03__windup__01__package_discovery.sh
#  -> used by 03__windup__02__analysis.sh
#  -> used by 04__wamt__01__analysis.sh
#  -> used by 09__findsecbugs__01__analysis.sh
#
# LIST_JAVA_SRC_INIT: list of Java applications initially provided as source
#  -> used by 03__windup__02__analysis.sh
#
# LIST_JAVA_SRC: list of Java source folders
#  -> used by 07__pmd__analysis.sh
#
# LANG_MAP_CSV: mapping betweeen application and languages
#  -> used by 00__generate_link_reports.sh
#
##############################################################################################################

# Executions
# -> all: OWASP-DC + MAI
# -> java-src: {{all}} + CSA + Windup + WAMT + Scancode + PMD + FindSecBugs
# -> java-bin: {{Java-src}} + Fernflower
# -> C# / python:  {{all}} + CSA

# ------ Do not modify

STEP=$(get_step)
SEPARATOR=','
export LOG_FILE=${REPORTS_DIR}/${STEP}__Weave.log

function identify() {
	APP_FILE_LIST=${1}
	APP_SRC_DIR=${2}
	APP_NAME=$(basename "${APP_SRC_DIR}")
	if (grep -q '.*\.java$' "${APP_FILE_LIST}"); then
		echo "${APP_SRC_DIR}" >>"${LIST_JAVA_SRC}"
		echo "${APP_SRC_DIR}" >>"${LIST_JAVA_SRC_INIT}"
		echo "${APP_NAME}${SEPARATOR}Java" >>"${LANG_MAP_CSV}"
	elif (grep -q -E '\.sln$' "${APP_FILE_LIST}"); then
		echo "${APP_SRC_DIR}" >>"${LIST_DOTNET}"
		echo "${APP_NAME}${SEPARATOR}C#" >>"${LANG_MAP_CSV}"
	elif (grep -q -E 'package.json$|Gruntfile.js$' "${APP_FILE_LIST}"); then
		echo "${APP_SRC_DIR}" >>"${LIST_JAVASCRIPT}"
		echo "${APP_NAME}${SEPARATOR}JavaScript" >>"${LANG_MAP_CSV}"
	elif (grep -q '.*\.py$' "${APP_FILE_LIST}"); then
		echo "${APP_SRC_DIR}" >>"${LIST_PYTHON}"
		echo "${APP_NAME}${SEPARATOR}Python" >>"${LANG_MAP_CSV}"
	elif (grep -q -E '\.cs$|\.cshtml$|\.dll$' "${APP_FILE_LIST}"); then
		echo "${APP_SRC_DIR}" >>"${LIST_DOTNET}"
		echo "${APP_NAME}${SEPARATOR}C#" >>"${LANG_MAP_CSV}"
	else
		echo "${APP_SRC_DIR}" >>"${LIST_OTHER}"
		echo "${APP_NAME}${SEPARATOR}Other" >>"${LANG_MAP_CSV}"
	fi
	rm -f "${APP_FILE_LIST}"
}

function sort_files() {
	for FILE in "$@"; do
		sort -o "${FILE}" "${FILE}"
	done
}

function weave() {
	GROUP=$(basename "${1}")
	SRC_DIR="${1}/src"
	TMP_DIR="${1}/tmp"

	# Remove tmp folder to avoid side effects
	rm -Rf "${TMP_DIR}"

	# All apps
	export LIST_ALL=${REPORTS_DIR}/list__${GROUP}__all_apps.txt
	export LIST_ALL_INIT=${REPORTS_DIR}/list__${GROUP}__all_init_apps.txt

	export LANG_MAP_CSV=${REPORTS_DIR}/list__${GROUP}__all_apps.csv

	# Currently the following application type can be analyzed ...
	# -> Java apps decompiled and initially provided as source code apps (zip/folder)
	export LIST_JAVA_SRC=${REPORTS_DIR}/list__${GROUP}__java-src.txt
	# -> Java binary apps
	export LIST_JAVA_BIN=${REPORTS_DIR}/list__${GROUP}__java-bin.txt
	# -> Java apps initially provided as source code
	export LIST_JAVA_SRC_INIT=${REPORTS_DIR}/list__${GROUP}__java-src-init.txt
	# -> JavaScript / Python / C# source code apps
	export LIST_JAVASCRIPT=${REPORTS_DIR}/list__${GROUP}__js.txt
	export LIST_PYTHON=${REPORTS_DIR}/list__${GROUP}__python.txt
	export LIST_DOTNET=${REPORTS_DIR}/list__${GROUP}__cs.txt
	# -> Other apps
	export LIST_OTHER=${REPORTS_DIR}/list__${GROUP}__other.txt

	rm -f "${LIST_ALL}" "${LIST_ALL_INIT}" "${LANG_MAP_CSV}" "${LIST_JAVA_SRC}" "${LIST_JAVA_BIN}" "${LIST_JAVA_SRC_INIT}" "${LIST_JAVASCRIPT}" "${LIST_PYTHON}" "${LIST_DOTNET}" "${LIST_OTHER}"
	touch "${LIST_ALL}" "${LIST_ALL_INIT}" "${LANG_MAP_CSV}" "${LIST_JAVA_SRC}" "${LIST_JAVA_BIN}" "${LIST_JAVA_SRC_INIT}" "${LIST_JAVASCRIPT}" "${LIST_PYTHON}" "${LIST_DOTNET}" "${LIST_OTHER}"

	# Add all java binary applications to ${LIST_JAVA_BIN}
	find "${1}" -maxdepth 1 -mindepth 1 -type f -name '*.[ejgrhw]ar' >"${LIST_JAVA_BIN}"

	# Add decompiled Java apps tp ${LIST_JAVA_SRC}
	while read -r APP; do
		APP_NAME=$(basename "${APP}")
		echo "${SRC_DIR}/${APP_NAME}" >>"${LIST_JAVA_SRC}"
		echo "${APP_NAME}${SEPARATOR}Java" >>"${LANG_MAP_CSV}"
		echo "${APP}" >>"${LIST_ALL_INIT}"
	done < <(find "${1}" -maxdepth 1 -mindepth 1 -type f -name '*.[ejgrhws]ar')

	# Add zipped source code to their category
	while read -r ARCHIVE; do
		APP_NAME=$(basename "${ARCHIVE}")
		APP_FILE_LIST=${ARCHIVE}.lst
		unzip -Z1 "${ARCHIVE}" >"${APP_FILE_LIST}"
		identify "${APP_FILE_LIST}" "${SRC_DIR}/${APP_NAME%.*}"
		echo "${ARCHIVE}" >>"${LIST_ALL_INIT}"
	done < <(find "${1}" -maxdepth 1 -mindepth 1 -type f -name '*.zip')

	# Add exploded source code directories to their category
	while read -r DIR; do
		DIR_NAME=$(basename "${DIR}")
		APP_FILE_LIST=${DIR}.list
		find "${DIR}" -type f >"${APP_FILE_LIST}"
		identify "${APP_FILE_LIST}" "${SRC_DIR}/${DIR_NAME}"
		echo "${DIR}" >>"${LIST_ALL_INIT}"
	done < <(find "${1}" -maxdepth 1 -mindepth 1 -type d -not -name 'src')

	cat "${LIST_JAVA_SRC}" "${LIST_JAVASCRIPT}" "${LIST_PYTHON}" "${LIST_DOTNET}" "${LIST_OTHER}" >"${LIST_ALL}"

	if [[ "${OWASP_ACTIVE}" == "true" ]]; then
		# List for OWASP DC
		export LIST_OWASP_DC=${REPORTS_DIR}/list__${GROUP}__owasp_dc.txt
		rm -f "${LIST_OWASP_DC}"
		touch "${LIST_OWASP_DC}"
		cat "${LIST_ALL}" >"${LIST_OWASP_DC}"
		sed -i.bak '/^.*\.[ejgrhw]ar$/d' "${LIST_OWASP_DC}"
		rm "${LIST_OWASP_DC}.bak"
		cat "${LIST_JAVA_BIN}" >>"${LIST_OWASP_DC}"
		sort_files "${LIST_OWASP_DC}"
	fi

	sort_files "${LIST_ALL}" "${LANG_MAP_CSV}" "${LIST_JAVA_SRC}" "${LIST_JAVA_BIN}" "${LIST_PYTHON}" "${LIST_JAVASCRIPT}" "${LIST_DOTNET}" "${LIST_OTHER}"

	COUNT_JAVA_BIN_APPS=$(count_lines "${LIST_JAVA_BIN}")
	COUNT_JAVA_APPS=$(count_lines "${LIST_JAVA_SRC}")
	COUNT_PY_APPS=$(count_lines "${LIST_PYTHON}")
	COUNT_JS_APPS=$(count_lines "${LIST_JAVASCRIPT}")
	COUNT_DOTNET_APPS=$(count_lines "${LIST_DOTNET}")
	COUNT_OTHER_APPS=$(count_lines "${LIST_OTHER}")
	COUNT_ALL_APPS=$(count_lines "${LIST_ALL}")

	log_console_info "[${GROUP}] Identified ${COUNT_ALL_APPS} apps: Java (${COUNT_JAVA_APPS} incl. ${COUNT_JAVA_BIN_APPS} binary), C# (${COUNT_DOTNET_APPS}), JavaScript (${COUNT_JS_APPS}), Python (${COUNT_PY_APPS}), Other (${COUNT_OTHER_APPS})"
}

function main() {
	for_each_group weave
}

main
