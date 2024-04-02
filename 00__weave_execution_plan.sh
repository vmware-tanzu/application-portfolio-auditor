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
#  -> used by 15__osv__01__anaylsis.sh
#  -> used by 15__osv__02__extract.sh
#  -> used by 16__archeo__01__anaylsis.sh
#  -> used by 16__archeo__02__extract.sh
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

export BASE_DIR="${REPORTS_DIR}/00__Weave"

# All apps
export LIST_ALL="${BASE_DIR}/list__all_apps.txt"
export LIST_ALL_INIT="${BASE_DIR}/list__all_init_apps.txt"
export LANG_MAP_CSV="${BASE_DIR}/list__all_apps.csv"

# Currently the following application type can be analyzed ...
# -> Java apps decompiled and initially provided as source code apps (zip/folder)
export LIST_JAVA_SRC="${BASE_DIR}/list__java-src.txt"
# -> Java binary apps
export LIST_JAVA_BIN="${BASE_DIR}/list__java-bin.txt"
# -> Java apps initially provided as source code
export LIST_JAVA_SRC_INIT="${BASE_DIR}/list__java-src-init.txt"
# -> JavaScript / Python / C# source code apps
export LIST_JAVASCRIPT="${BASE_DIR}/list__js.txt"
export LIST_PYTHON="${BASE_DIR}/list__python.txt"
export LIST_DOTNET="${BASE_DIR}/list__cs.txt"
# -> Other apps
export LIST_OTHER="${BASE_DIR}/list__other.txt"

function identify() {
	local -r APP_FILE_LIST=${1}
	local -r APP_SRC_DIR=${2}
	local -r APP_NAME=$(basename "${APP_SRC_DIR}")
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
		sort -f -o "${FILE}" "${FILE}"
	done
}

function main() {
	rm -Rf "${BASE_DIR}"
	mkdir -p "${BASE_DIR}"

	rm -f "${LIST_ALL}" "${LIST_ALL_INIT}" "${LANG_MAP_CSV}" "${LIST_JAVA_SRC}" "${LIST_JAVA_BIN}" "${LIST_JAVA_SRC_INIT}" "${LIST_JAVASCRIPT}" "${LIST_PYTHON}" "${LIST_DOTNET}" "${LIST_OTHER}"
	touch "${LIST_ALL}" "${LIST_ALL_INIT}" "${LANG_MAP_CSV}" "${LIST_JAVA_SRC}" "${LIST_JAVA_BIN}" "${LIST_JAVA_SRC_INIT}" "${LIST_JAVASCRIPT}" "${LIST_PYTHON}" "${LIST_DOTNET}" "${LIST_OTHER}"

	# Add all java binary applications to ${LIST_JAVA_BIN}
	find "${APP_GROUP_DIR}" -maxdepth 1 -mindepth 1 -type f -name '*.[ejgrhw]ar' >"${LIST_JAVA_BIN}"

	# Add decompiled Java apps to ${LIST_JAVA_SRC}
	while read -r APP; do
		APP_NAME=$(basename "${APP}")
		echo "${APP_GROUP_SRC_DIR}/${APP_NAME}" >>"${LIST_JAVA_SRC}"
		echo "${APP_NAME}${SEPARATOR}Java" >>"${LANG_MAP_CSV}"
		echo "${APP}" >>"${LIST_ALL_INIT}"
	done < <(find "${APP_GROUP_DIR}" -maxdepth 1 -mindepth 1 -type f -name '*.[ejgrhws]ar')

	# Add zipped source code to their category
	while read -r ARCHIVE; do
		APP_NAME=$(basename "${ARCHIVE}")
		APP_FILE_LIST=${ARCHIVE}.lst
		unzip -Z1 "${ARCHIVE}" >"${APP_FILE_LIST}"
		identify "${APP_FILE_LIST}" "${APP_GROUP_SRC_DIR}/${APP_NAME%.*}"
		echo "${ARCHIVE}" >>"${LIST_ALL_INIT}"
	done < <(find "${APP_GROUP_DIR}" -maxdepth 1 -mindepth 1 -type f -name '*.zip')

	# Add exploded source code directories to their category
	while read -r DIR; do
		DIR_NAME=$(basename "${DIR}")
		APP_FILE_LIST=${DIR}.list
		find "${DIR}" -type f >"${APP_FILE_LIST}"
		identify "${APP_FILE_LIST}" "${APP_GROUP_SRC_DIR}/${DIR_NAME}"
		echo "${DIR}" >>"${LIST_ALL_INIT}"
	done < <(find "${APP_GROUP_DIR}" -maxdepth 1 -mindepth 1 -type d -not -name 'src')

	cat "${LIST_JAVA_SRC}" "${LIST_JAVASCRIPT}" "${LIST_PYTHON}" "${LIST_DOTNET}" "${LIST_OTHER}" >"${LIST_ALL}"

	if [[ "${OWASP_ACTIVE}" == "true" ]]; then
		# List for OWASP DC
		export LIST_OWASP_DC=${BASE_DIR}/list__owasp_dc.txt
		rm -f "${LIST_OWASP_DC}"
		touch "${LIST_OWASP_DC}"
		cat "${LIST_ALL}" >"${LIST_OWASP_DC}"
		sed -i.bak '/^.*\.[ejgrhw]ar$/d' "${LIST_OWASP_DC}"
		rm "${LIST_OWASP_DC}.bak"
		cat "${LIST_JAVA_BIN}" >>"${LIST_OWASP_DC}"
		sort_files "${LIST_OWASP_DC}"
	fi

	sort_files "${LIST_ALL_INIT}" "${LIST_ALL}" "${LANG_MAP_CSV}" "${LIST_JAVA_SRC}" "${LIST_JAVA_SRC_INIT}" "${LIST_JAVA_BIN}" "${LIST_PYTHON}" "${LIST_JAVASCRIPT}" "${LIST_DOTNET}" "${LIST_OTHER}"

	COUNT_JAVA_BIN_APPS=$(count_lines "${LIST_JAVA_BIN}")
	COUNT_JAVA_APPS=$(count_lines "${LIST_JAVA_SRC}")
	COUNT_PY_APPS=$(count_lines "${LIST_PYTHON}")
	COUNT_JS_APPS=$(count_lines "${LIST_JAVASCRIPT}")
	COUNT_DOTNET_APPS=$(count_lines "${LIST_DOTNET}")
	COUNT_OTHER_APPS=$(count_lines "${LIST_OTHER}")
	COUNT_ALL_APPS=$(count_lines "${LIST_ALL}")

	log_console_info "[${APP_GROUP}] Identified ${COUNT_ALL_APPS} apps: Java (${COUNT_JAVA_APPS} incl. ${COUNT_JAVA_BIN_APPS} binary), C# (${COUNT_DOTNET_APPS}), JavaScript (${COUNT_JS_APPS}), Python (${COUNT_PY_APPS}), Other (${COUNT_OTHER_APPS})"
}

main
