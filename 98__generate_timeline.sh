#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Generate the timeline report for all conducted steps.
##############################################################################################################

# ----- Please adjust
#set -x

# --- Do not edit below this line ---
STEP=$(get_step)
START_TAG=">>>>>>> \["
END_TAG="<<<<<<< \["
CAT_PREPARATION="Preparation"
CAT_ANALYSIS="Analysis"
CAT_EXTRACTION="Extraction"

INFO_REPORT="${REPORTS_DIR}/info.html"
TEMPLATE_DIR="${INSTALL_DIR}/templating"
MUSTACHE="${TEMPLATE_DIR}/mo_${MUSTACHE_VERSION}"

export LOG_FILE="${REPORTS_DIR}/${STEP}__generate_timeline.log"

function add_entry() {
	local CATEGORY="$1"
	local ENTRY_FILTER="$2"
	local LOG_URL="$3"
	local ENTRY_LABEL="${4-$(echo "${ENTRY_FILTER}" | cut -d"." -f 1)}"

	if [ -n "${ENTRY_FILTER}" ] && [ -n "${CATEGORY}" ]; then
		START=$(grep "${ENTRY_FILTER}" "${TIMELINE_LOG}" | grep "${START_TAG}" | cut -d" " -f 2 | tr -d '[]')
		END=$(grep "${ENTRY_FILTER}" "${TIMELINE_LOG}" | grep "${END_TAG}" | cut -d" " -f 2 | tr -d '[]')

		if [ -n "${START}" ] && [ -n "${END}" ]; then
			START_DATE=$(echo "${START}" | awk -F_ '{printf "%s-%s-%sT%s:%s:%s.000Z",$1,$2,$3,$5,$6,$7}')
			END_DATE=$(echo "${END}" | awk -F_ '{printf "%s-%s-%sT%s:%s:%s.999Z",$1,$2,$3,$5,$6,$7}')
			if [[ -f "${REPORTS_DIR}/${LOG_URL}" ]]; then
				jq '.[0].data += [{"label": "'"${ENTRY_LABEL}"'", "data": [{"timeRange": ["'"${START_DATE}"'","'"${END_DATE}"'"], "val": "'"${CATEGORY}"'", "url": "'"${LOG_URL}"'"}]}]' "${TIMELINE_JSON}" >"${TIMELINE_JSON_TMP}"
			else
				jq '.[0].data += [{"label": "'"${ENTRY_LABEL}"'", "data": [{"timeRange": ["'"${START_DATE}"'","'"${END_DATE}"'"], "val": "'"${CATEGORY}"'"}]}]' "${TIMELINE_JSON}" >"${TIMELINE_JSON_TMP}"
			fi
			mv "${TIMELINE_JSON_TMP}" "${TIMELINE_JSON}"
		fi
	fi
}

function main() {

	export TIMELINE_LOG="${REPORTS_DIR}/98__timeline.log"
	export TIMELINE_JSON="${REPORTS_DIR}/98__timeline.json"
	export TIMELINE_JSON_TMP="${REPORTS_DIR}/timeline.json.tmp"

	if [[ -f "${TIMELINE_LOG}" ]]; then

		# Get the first group
		APP_GROUP=$(find "${APP_DIR_IN}" -maxdepth 1 -mindepth 1 -type d -print -quit)
		# Log files
		RUN_LOG="./run.log"
		FERNFLOWER_LOG="./01__Fernflower.log"
		UNPACK_LOG="./01__unpack_sources.log"
		CSA_LOG="./02__CSA.log"
		WINDUP_LOG="./03__WINDUP.log"
		WAMT_LOG="./04__WAMT.log"
		ODC_LOG="./05__OWASP_DC__${APP_GROUP}.log"
		SCANCODE_LOG="./06__SCANCODE.log"
		PMD_LOG="./07__PMD.log"
		LANGUAGES_LOG="./08__LINGUIST.log"
		FSB_LOG="./09__FindSecBugs.log"
		MAI_LOG="./10__MAI.log"
		SLSCAN_LOG="./11__SLSCAN.log"
		INSIDER_LOG="./12__INSIDER.log"
		GRYPE_LOG="./13__GRYPE.log"
		TRIVY_LOG="./14__TRIVY.log"
		OSV_LOG="./15__OSV.log"
		ARCHEO_LOG="./16__ARCHEO.log"
		BEARER_LOG="./17__BEARER.log"

		# Initiate the JSON file
		echo "[]" >"${TIMELINE_JSON}"

		# Add the group
		jq '. += [{"group": "Steps", "data": []}]' "${TIMELINE_JSON}" >"${TIMELINE_JSON_TMP}"
		mv "${TIMELINE_JSON_TMP}" "${TIMELINE_JSON}"

		add_entry "${CAT_PREPARATION}" "00__check_prereqs.sh" "${RUN_LOG}"
		add_entry "${CAT_PREPARATION}" "00__unpack_all_tools.sh" "${RUN_LOG}"
		add_entry "${CAT_PREPARATION}" "00__verify_prereqs.sh" "${RUN_LOG}"
		add_entry "${CAT_PREPARATION}" "00__weave_execution_plan.sh" "${RUN_LOG}"
		add_entry "${CAT_PREPARATION}" "01__fernflower_decompile.sh" "${FERNFLOWER_LOG}"
		add_entry "${CAT_PREPARATION}" "01__unpack_sources.sh" "${UNPACK_LOG}"
		add_entry "${CAT_ANALYSIS}" "02__csa__01__analysis.sh" "${CSA_LOG}" "02__csa"
		add_entry "${CAT_EXTRACTION}" "02__csa__02__extract.sh" "${CSA_LOG}" "02__csa"
		add_entry "${CAT_ANALYSIS}" "03__windup__01__package_discovery.sh" "${WINDUP_LOG}" "03__windup_package"
		add_entry "${CAT_ANALYSIS}" "03__windup__02__analysis.sh" "${WINDUP_LOG}" "03__windup"
		add_entry "${CAT_EXTRACTION}" "03__windup__03__extract.sh" "${WINDUP_LOG}" "03__windup"
		add_entry "${CAT_ANALYSIS}" "04__wamt__01__analysis.sh" "${WAMT_LOG}" "04__wamt"
		add_entry "${CAT_EXTRACTION}" "04__wamt__02__extract.sh" "${WAMT_LOG}" "04__wamt"
		add_entry "${CAT_ANALYSIS}" "05__owasp_dc__01__analysis.sh" "${ODC_LOG}" "05__owasp_dc"
		add_entry "${CAT_EXTRACTION}" "05__owasp_dc__02__extract.sh" "${ODC_LOG}" "05__owasp_dc"
		add_entry "${CAT_ANALYSIS}" "06__scancode__01__analysis.sh" "${SCANCODE_LOG}" "06__scancode"
		add_entry "${CAT_EXTRACTION}" "06__scancode__02__extract.sh" "${SCANCODE_LOG}" "06__scancode"
		add_entry "${CAT_ANALYSIS}" "07__pmd__01__analysis.sh" "${PMD_LOG}" "07__pmd"
		add_entry "${CAT_EXTRACTION}" "07__pmd__02__extract.sh" "${PMD_LOG}" "07__pmd"
		add_entry "${CAT_ANALYSIS}" "08__linguist_and_cloc__01__analysis.sh" "${LANGUAGES_LOG}" "08__linguist_and_cloc"
		add_entry "${CAT_EXTRACTION}" "08__linguist_and_cloc__02__extract.sh" "${LANGUAGES_LOG}" "08__linguist_and_cloc"
		add_entry "${CAT_ANALYSIS}" "09__findsecbugs__01__analysis.sh" "${FSB_LOG}" "09__findsecbugs"
		add_entry "${CAT_EXTRACTION}" "09__findsecbugs__02__extract.sh" "${FSB_LOG}" "09__findsecbugs"
		add_entry "${CAT_ANALYSIS}" "10__mai__analysis.sh" "${MAI_LOG}" "10__mai"
		add_entry "${CAT_EXTRACTION}" "10__mai__extract.sh" "${MAI_LOG}" "10__mai"
		add_entry "${CAT_ANALYSIS}" "11__slscan__analysis.sh" "${SLSCAN_LOG}" "11__slscan"
		add_entry "${CAT_EXTRACTION}" "11__slscan__extract.sh" "${SLSCAN_LOG}" "11__slscan"
		add_entry "${CAT_ANALYSIS}" "12__insider__analysis.sh" "${INSIDER_LOG}" "12__insider"
		add_entry "${CAT_EXTRACTION}" "12__insider__extract.sh" "${INSIDER_LOG}" "12__insider"
		add_entry "${CAT_ANALYSIS}" "13__grype__analysis.sh" "${GRYPE_LOG}" "13__grype"
		add_entry "${CAT_EXTRACTION}" "13__grype__extract.sh" "${GRYPE_LOG}" "13__grype"
		add_entry "${CAT_ANALYSIS}" "14__trivy__analysis.sh" "${TRIVY_LOG}" "14__trivy"
		add_entry "${CAT_EXTRACTION}" "14__trivy__extract.sh" "${TRIVY_LOG}" "14__trivy"
		add_entry "${CAT_ANALYSIS}" "15__osv__analysis.sh" "${OSV_LOG}" "15__osv"
		add_entry "${CAT_EXTRACTION}" "15__osv__extract.sh" "${OSV_LOG}" "15__osv"
		add_entry "${CAT_ANALYSIS}" "16__archeo__analysis.sh" "${ARCHEO_LOG}" "16__archeo"
		add_entry "${CAT_EXTRACTION}" "16__archeo__extract.sh" "${ARCHEO_LOG}" "16__archeo"
		add_entry "${CAT_ANALYSIS}" "17__bearer__analysis.sh" "${BEARER_LOG}" "17__bearer"
		add_entry "${CAT_EXTRACTION}" "17__bearer__extract.sh" "${BEARER_LOG}" "17__bearer"
		add_entry "${CAT_PREPARATION}" "97__generate_reports.sh" "${RUN_LOG}" "98__generate_reports"

		rm -f "${TIMELINE_JSON_TMP}"

		# Generate timeline report
		REPORT_VARS="${REPORTS_DIR}/98__report_vars.sh"
		source "${REPORT_VARS}"
		{
			${MUSTACHE} "${TEMPLATE_DIR}/info_timeline_01.mo"
			cat "${TIMELINE_JSON}"
			${MUSTACHE} "${TEMPLATE_DIR}/info_timeline_02.mo"
		} >"${INFO_REPORT}"

		rm -f "${TIMELINE_JSON}" "${REPORT_VARS}"
	fi

}

main
