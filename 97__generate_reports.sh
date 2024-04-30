#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Generate HTML file linking all reports.
##############################################################################################################

# ----- Please adjust
#set -x
export NAV_LINK="https://github.com/vmware-tanzu/application-portfolio-auditor"
export NAV_ICON="bi bi-github"

# ------ Do not modify
TEMPLATE_DIR=${DIST_DIR}/templating
MUSTACHE="${TEMPLATE_DIR}/mo_${MUSTACHE_VERSION}"
export LOG_FILE CSA_URL
LOG_FILE=/dev/null
SEPARATOR=','
if [[ "${PACKAGE_CF}" == "true" || "${PACKAGE_K8}" == "true" ]]; then
	CSA_URL='./csa/'
else
	CSA_URL='http://localhost:3001/'
fi
REPORT_VARS="${REPORTS_DIR}/98__report_vars.sh"
SUMMARY_CSV="${REPORTS_DIR}/99__results__all.csv"

RESULT_CSV_FILE_NAME="Audit__${TIMESTAMP}__all__results.csv"
SUMMARY_CSV_FULL_NAME="${REPORTS_DIR}/${RESULT_CSV_FILE_NAME}"
CLOUD_TMP_CSV="${REPORTS_DIR}/99__results__cloud.csv"
SECURITY_TMP_CSV="${REPORTS_DIR}/99__results__security.csv"
QUALITY_TMP_CSV="${REPORTS_DIR}/99__results__quality.csv"

# All relevant variables for the generated reports
REPORT_VARIABLES=(
	# General
	"TOOLS_COUNT" "APP_GROUP" "APP_COUNT" "CSV_URL" "NAV_LINK" "NAV_ICON" "HAS_MULTIPLE_APPS" "HAS_MULTIPLE_TOOLS"

	# Cloud-readiness
	"TOOLS_CLOUD_COUNT" "HAS_MULTIPLE_CLOUD_TOOLS" "HAS_WINDUP" "HAS_WINDUP_REPORT" "HAS_WINDUP_PACKAGES_REPORT" "HAS_WINDUP_OR_PACKAGES_REPORT" "WINDUP_URL" "WINDUP_PACKAGES" "WINDUP_CSV_ALL" "WINDUP_LOG" "WAMT_URL" "WAMT_LOG" "HAS_CSA_REPORT" "HAS_WAMT_REPORT" "HAS_CLOUD_REPORT" "HAS_INDEX_CLOUD_REPORT"

	# Quality
	"HAS_QUALITY_REPORT" "TOOLS_QUALITY_COUNT" "HAS_MULTIPLE_QUALITY_TOOLS" "HAS_PMD_REPORT" "PMD_URL" "PMD_LOG" "HAS_FSB_REPORT" "FSB_URL" "FSB_LOG" "HAS_MAI_REPORT" "MAI_URL" "MAI_LOG" "HAS_ARCHEO_REPORT" "ARCHEO_URL" "ARCHEO_LOG"

	# Security
	"HAS_SECURITY_REPORT" "TOOLS_SECURITY_COUNT" "HAS_SECURITY_REPORT_TABLE" "HAS_MULTIPLE_SECURITY_TOOLS" "SCANCODE_URL" "SCANCODE_LOG" "SLSCAN_URL" "SLSCAN_LOG" "INSIDER_URL" "INSIDER_LOG" "ODC_URL" "ODC_LOG" "GRYPE_URL" "GRYPE_LOG" "TRIVY_URL" "TRIVY_LOG" "HAS_SCANCODE_REPORT" "HAS_ODC_REPORT" "HAS_SLSCAN_REPORT" "HAS_INSIDER_REPORT" "HAS_GRYPE_REPORT" "HAS_TRIVY_REPORT" "HAS_OSV_REPORT" "OSV_URL" "OSV_LOG" "HAS_BEARER_REPORT" "BEARER_URL" "BEARER_LOG"

	# Language
	"TOOLS_LANGUAGE_COUNT" "HAS_MULTIPLE_LANGUAGE_TOOLS" "LANGUAGES_URL" "LANGUAGES_LOG" "HAS_LANGUAGES_REPORT"
)

# Replace the sort function to sort the lines after the header
function sort_wo_header() {
	awk 'NR<3{print $0;next}{print $0| "sort -f"}' "${1}"
}

# Export all relevant variables to generate the reports
function export_vars() {

	for VARIABLE in "${REPORT_VARIABLES[@]}"; do
		export "${VARIABLE}"
	done

	TOOLS_COUNT=0
	TOOLS_SECURITY_COUNT=0
	TOOLS_CLOUD_COUNT=0
	TOOLS_QUALITY_COUNT=0
	TOOLS_LANGUAGE_COUNT=0

	APP_COUNT=$(count_lines "${REPORTS_DIR}/00__Weave/list__all_apps.txt")

	CSV_URL="./${RESULT_CSV_FILE_NAME}"

	WINDUP_URL="./03__WINDUP/index.html"
	WINDUP_PACKAGES="./03__WINDUP__packages/"
	WINDUP_CSV_ALL="./03__WINDUP/AllIssues.csv"
	WINDUP_LOG="./03__WINDUP.log"

	WAMT_URL="./04__WAMT/"
	WAMT_LOG="./04__WAMT.log"

	ODC_URL="./05__OWASP_DC/"
	ODC_LOG="./05__OWASP_DC.log"

	SCANCODE_URL="./06__SCANCODE/"
	SCANCODE_LOG="./06__SCANCODE.log"

	PMD_URL="./07__PMD/"
	PMD_LOG="./07__PMD.log"

	LANGUAGES_URL="./languages.html"
	LANGUAGES_LOG="./08__LINGUIST.log"

	FSB_URL="./09__FindSecBugs/"
	FSB_LOG="./09__FindSecBugs.log"

	MAI_URL="./10__MAI/"
	MAI_LOG="./10__MAI.log"

	SLSCAN_URL="./11__SLSCAN/"
	SLSCAN_LOG="./11__SLSCAN.log"

	INSIDER_URL="./12__INSIDER/"
	INSIDER_LOG="./12__INSIDER.log"

	GRYPE_URL="./13__GRYPE/"
	GRYPE_LOG="./13__GRYPE.log"

	TRIVY_URL="./14__TRIVY/"
	TRIVY_LOG="./14__TRIVY.log"

	OSV_URL="./15__OSV/"
	OSV_LOG="./15__OSV.log"

	ARCHEO_URL="./16__ARCHEO/"
	ARCHEO_LOG="./16__ARCHEO.log"

	BEARER_URL="./17__BEARER/"
	BEARER_LOG="./17__BEARER.log"

	CSA_REPORT=$(find "${REPORTS_DIR}" -maxdepth 3 -mindepth 3 -type f -name 'csa.db' | grep -c 'CSA' || true)
	if ((CSA_REPORT > 0)); then
		export HAS_CSA_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 1))
		TOOLS_CLOUD_COUNT=$((TOOLS_CLOUD_COUNT + 1))
	else
		export HAS_CSA_REPORT=''
	fi

	export HAS_WINDUP=''
	WINDUP_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name 'index.html' | grep -c 'WINDUP' || true)
	if ((WINDUP_REPORT > 0)); then
		export HAS_WINDUP_REPORT=TRUE
		HAS_WINDUP=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 1))
		TOOLS_CLOUD_COUNT=$((TOOLS_CLOUD_COUNT + 1))
	else
		export HAS_WINDUP_REPORT=''
	fi

	WINDUP_PACKAGES_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name '_all.packages' | grep -c 'WINDUP__packages' || true)

	if ((WINDUP_PACKAGES_REPORT > 0)); then
		export HAS_WINDUP_PACKAGES_REPORT=TRUE
		if [[ "${HAS_WINDUP}" == '' ]]; then
			TOOLS_COUNT=$((TOOLS_COUNT + 1))
			TOOLS_CLOUD_COUNT=$((TOOLS_CLOUD_COUNT + 1))
		fi
	else
		export HAS_WINDUP_PACKAGES_REPORT=''
	fi

	WAMT_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name '_results_extracted.csv' | grep -c 'WAMT' || true)
	if ((WAMT_REPORT > 0)); then
		export HAS_WAMT_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 1))
		TOOLS_CLOUD_COUNT=$((TOOLS_CLOUD_COUNT + 1))
	else
		export HAS_WAMT_REPORT=''
	fi

	export HAS_QUALITY_OR_LANGUAGE_REPORT=''
	export HAS_QUALITY_REPORT=''
	SCANCODE_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name '_results_extracted.csv' | grep -c 'SCANCODE' || true)
	if ((SCANCODE_REPORT > 0)); then
		export HAS_SCANCODE_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 1))
		TOOLS_QUALITY_COUNT=$((TOOLS_QUALITY_COUNT + 1))
		HAS_QUALITY_REPORT=TRUE
		HAS_QUALITY_OR_LANGUAGE_REPORT=TRUE
	else
		export HAS_SCANCODE_REPORT=''
	fi

	PMD_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name '_results_extracted.csv' | grep -c 'PMD' || true)
	if ((PMD_REPORT > 0)); then
		export HAS_PMD_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 1))
		TOOLS_QUALITY_COUNT=$((TOOLS_QUALITY_COUNT + 1))
		HAS_QUALITY_REPORT=TRUE
		HAS_QUALITY_OR_LANGUAGE_REPORT=TRUE
	else
		export HAS_PMD_REPORT=''
	fi

	MAI_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name '_results_extracted.csv' | grep -c 'MAI' || true)
	if ((MAI_REPORT > 0)); then
		export HAS_MAI_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 1))
		TOOLS_QUALITY_COUNT=$((TOOLS_QUALITY_COUNT + 1))
		HAS_QUALITY_REPORT=TRUE
		HAS_QUALITY_OR_LANGUAGE_REPORT=TRUE
	else
		export HAS_MAI_REPORT=''
	fi

	LANGUAGES_REPORT=$(find "${REPORTS_DIR}" -maxdepth 1 -mindepth 1 -type d | grep -c '__LINGUIST' || true)
	if ((LANGUAGES_REPORT > 0)); then
		export HAS_LANGUAGES_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 2))
		TOOLS_LANGUAGE_COUNT=$((TOOLS_LANGUAGE_COUNT + 2))
		HAS_QUALITY_OR_LANGUAGE_REPORT=TRUE
	else
		export HAS_LANGUAGES_REPORT=''
	fi

	export HAS_SECURITY_REPORT=''
	ODC_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name '*_dc_report.html' | grep -c 'OWASP_DC' || true)
	if ((ODC_REPORT > 0)); then
		export HAS_ODC_REPORT=TRUE
		HAS_SECURITY_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 1))
		TOOLS_SECURITY_COUNT=$((TOOLS_SECURITY_COUNT + 1))
	else
		export HAS_ODC_REPORT=''
	fi

	FSB_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name '_results_extracted.csv' | grep -c 'FindSecBugs' || true)
	if ((FSB_REPORT > 0)); then
		export HAS_FSB_REPORT=TRUE
		HAS_SECURITY_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 1))
		TOOLS_SECURITY_COUNT=$((TOOLS_SECURITY_COUNT + 1))
	else
		export HAS_FSB_REPORT=''
	fi

	SLSCAN_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name '*.txt' | grep -c 'SLSCAN' || true)
	if ((SLSCAN_REPORT > 0)); then
		export HAS_SLSCAN_REPORT=TRUE
		HAS_SECURITY_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 1))
		TOOLS_SECURITY_COUNT=$((TOOLS_SECURITY_COUNT + 1))
	else
		export HAS_SLSCAN_REPORT=''
	fi

	INSIDER_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name '*.html' | grep -c 'INSIDER' || true)
	if ((INSIDER_REPORT > 0)); then
		export HAS_INSIDER_REPORT=TRUE
		HAS_SECURITY_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 1))
		TOOLS_SECURITY_COUNT=$((TOOLS_SECURITY_COUNT + 1))
	else
		export HAS_INSIDER_REPORT=''
	fi

	GRYPE_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name '_results_extracted.csv' | grep -c 'GRYPE' || true)
	if ((GRYPE_REPORT > 0)); then
		export HAS_GRYPE_REPORT=TRUE
		HAS_SECURITY_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 2))
		TOOLS_SECURITY_COUNT=$((TOOLS_SECURITY_COUNT + 2))
	else
		export HAS_GRYPE_REPORT=''
	fi

	TRIVY_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name '_results_extracted.csv' | grep -c 'TRIVY' || true)
	if ((TRIVY_REPORT > 0)); then
		export HAS_TRIVY_REPORT=TRUE
		HAS_SECURITY_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 1))
		TOOLS_SECURITY_COUNT=$((TOOLS_SECURITY_COUNT + 1))
	else
		export HAS_TRIVY_REPORT=''
	fi

	OSV_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name '_results__security__osv.csv' | grep -c 'OSV' || true)
	if ((OSV_REPORT > 0)); then
		export HAS_OSV_REPORT=TRUE
		HAS_SECURITY_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 1))
		TOOLS_SECURITY_COUNT=$((TOOLS_SECURITY_COUNT + 1))
	else
		export HAS_OSV_REPORT=''
	fi

	BEARER_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name '_results__security__bearer.csv' | grep -c 'BEARER' || true)
	if ((BEARER_REPORT > 0)); then
		export HAS_BEARER_REPORT=TRUE
		HAS_SECURITY_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 1))
		TOOLS_SECURITY_COUNT=$((TOOLS_SECURITY_COUNT + 1))
	else
		export HAS_BEARER_REPORT=''
	fi

	ARCHEO_REPORT=$(find "${REPORTS_DIR}" -maxdepth 2 -mindepth 2 -type f -name '_results__quality__archeo.csv' | grep -c 'ARCHEO' || true)
	if ((ARCHEO_REPORT > 0)); then
		export HAS_ARCHEO_REPORT=TRUE
		HAS_QUALITY_OR_LANGUAGE_REPORT=TRUE
		HAS_QUALITY_REPORT=TRUE
		TOOLS_COUNT=$((TOOLS_COUNT + 1))
		TOOLS_QUALITY_COUNT=$((TOOLS_QUALITY_COUNT + 1))
	else
		export HAS_ARCHEO_REPORT=''
	fi

	if ((TOOLS_CLOUD_COUNT > 1)); then
		export HAS_MULTIPLE_CLOUD_TOOLS=TRUE
	else
		export HAS_MULTIPLE_CLOUD_TOOLS=''
	fi

	if ((TOOLS_LANGUAGE_COUNT > 1)); then
		export HAS_MULTIPLE_LANGUAGE_TOOLS=TRUE
	else
		export HAS_MULTIPLE_LANGUAGE_TOOLS=''
	fi

	if ((TOOLS_QUALITY_COUNT > 1)); then
		export HAS_MULTIPLE_QUALITY_TOOLS=TRUE
	else
		export HAS_MULTIPLE_QUALITY_TOOLS=''
	fi

	if ((TOOLS_SECURITY_COUNT > 1)); then
		export HAS_MULTIPLE_SECURITY_TOOLS=TRUE
	else
		export HAS_MULTIPLE_SECURITY_TOOLS=''
	fi

	if [[ "${HAS_WINDUP}" == TRUE || "${HAS_WAMT_REPORT}" == TRUE || "${HAS_CSA_REPORT}" == TRUE ]]; then
		export HAS_CLOUD_REPORT=TRUE
	else
		export HAS_CLOUD_REPORT=''
	fi

	if [[ "${HAS_WINDUP}" == TRUE || "${HAS_WINDUP_PACKAGES_REPORT}" == TRUE ]]; then
		export HAS_WINDUP_OR_PACKAGES_REPORT=TRUE

	else
		export HAS_WINDUP_OR_PACKAGES_REPORT=''
	fi

	if [[ "${HAS_CLOUD_REPORT}" == TRUE || "${HAS_WINDUP_PACKAGES_REPORT}" == TRUE ]]; then
		export HAS_INDEX_CLOUD_REPORT=TRUE
	else
		export HAS_INDEX_CLOUD_REPORT=''
	fi

	if ((APP_COUNT > 1)); then
		HAS_MULTIPLE_APPS=TRUE
	else
		HAS_MULTIPLE_APPS=''
	fi

	if ((TOOLS_COUNT > 1)); then
		HAS_MULTIPLE_TOOLS=TRUE
	else
		HAS_MULTIPLE_TOOLS=''
	fi

	{
		echo "#!/usr/bin/env bash"
		for VARIABLE in "${REPORT_VARIABLES[@]}"; do
			echo "$(declare -p ${VARIABLE})"
		done
		echo "export REPORT_TIMESTAMP='${REPORT_TIMESTAMP}'"
	} >"${REPORT_VARS}"
	chmod +x "${REPORT_VARS}"

	# shellcheck source=/dev/null
	source "${REPORT_VARS}"
}

# Add the language column
function add_language_column() {
	TMP_CSV=${1}
	export LANG_CSV="${REPORTS_DIR}/00__Weave/list__all_apps.csv"
	# Add the language column
	{
		echo "Applications${SEPARATOR}Language"
		cat "${LANG_CSV}"
	} >"${TMP_CSV}.lang"

	paste -d "${SEPARATOR}" "${TMP_CSV}.lang" <(cut -d "${SEPARATOR}" -f2- "${TMP_CSV}") >"${TMP_CSV}.tmp.tmp"

	# Remove spaces and tabs, excepted in the header.
	head -n 1 "${TMP_CSV}.tmp.tmp" | tr -d "\t" >"${TMP_CSV}.tmp"
	sed '1d' "${TMP_CSV}.tmp.tmp" | tr -d " \t" >>"${TMP_CSV}.tmp"

	mv "${TMP_CSV}.tmp" "${TMP_CSV}"
	rm -f "${TMP_CSV}.lang" "${TMP_CSV}.tmp.tmp"
}

function concatenate_csv() {
	CSV=${1}
	TMP_CSV=${2}
	if [[ -f "${CSV}" ]]; then
		# Checking whether the temporary file exists or not
		if [[ -f "${TMP_CSV}" ]]; then
			# Concatenating content of current CSV with TMP_CSV
			paste -d "${SEPARATOR}" "${TMP_CSV}" <(sort_wo_header "${CSV}" | cut -d "${SEPARATOR}" -f2-) >"${TMP_CSV}.tmp"
			# Moving temporary file back to original name
			mv "${TMP_CSV}.tmp" "${TMP_CSV}"
		else
			# If TMP_CSV doesn't exist, we copy the content of current CSV file to it.
			sort_wo_header "${CSV}" >"${TMP_CSV}"
		fi
	fi
}

# Generate the CSV file for the cloud.html page
function generate_cloud_csv() {
	TMP_CSV=${1}
	rm -f "${TMP_CSV}"

	#export LANG_CSV="${REPORTS_DIR}/00__Weave/list__all_apps.csv"
	export CSA_CSV="${REPORTS_DIR}/02__CSA/_results_extracted.csv"
	export WINDUP_CSV="${REPORTS_DIR}/03__WINDUP/_results_extracted.csv"
	export WAMT_CSV="${REPORTS_DIR}/04__WAMT/_results_extracted.csv"

	# Debug info to compare the result counts
	#echo "LANG_CSV        - $(cat $LANG_CSV | wc -l |  tr -d ' \t') entries - $LANG_CSV"
	#echo "CSA_CSV         - $(cat $CSA_CSV | wc -l |  tr -d ' \t') entries - $CSA_CSV"
	#echo "WINDUP_CSV      - $(cat $WINDUP_CSV | wc -l |  tr -d ' \t')-1 entries - $WINDUP_CSV"
	#echo "WAMT_CSV        - $(cat $WAMT_CSV | wc -l |  tr -d ' \t')-1 entries - $WAMT_CSV"

	if [[ -f "${WINDUP_CSV}" ]]; then
		if [[ -f "${CSA_CSV}" ]]; then
			echo "Applications${SEPARATOR}CSA tech score" >"${CSA_CSV}.tmp"
			grep "${APP_GROUP}" "${CSA_CSV}" | cut -d "${SEPARATOR}" -f2,4 | sort -f | uniq >>"${CSA_CSV}.tmp"

			# Merge Windup and CSA results
			paste -d "${SEPARATOR}" "${CSA_CSV}.tmp" <(cut -d "${SEPARATOR}" -f2- "${WINDUP_CSV}") | tr -d '\t' >>"${TMP_CSV}"

			rm -f "${CSA_CSV}.tmp"
		else
			cat "${WINDUP_CSV}" >>"${TMP_CSV}"
		fi
	elif [[ -f "${CSA_CSV}" ]]; then
		echo "Applications${SEPARATOR}CSA tech score" >"${TMP_CSV}"
		grep "${APP_GROUP}" "${CSA_CSV}" | cut -d "${SEPARATOR}" -f2,4 | sort -f | uniq >>"${TMP_CSV}"
	fi

	if [[ -f "${WAMT_CSV}" ]]; then
		if [ -s "${TMP_CSV}" ]; then
			paste -d "${SEPARATOR}" "${TMP_CSV}" <(cut -d "${SEPARATOR}" -f2- "${WAMT_CSV}") >"${WAMT_CSV}.tmp"
			mv "${WAMT_CSV}.tmp" "${TMP_CSV}"
		else
			cat "${WAMT_CSV}" >>"${TMP_CSV}"
		fi
	fi
	if [[ -f "${TMP_CSV}" ]]; then
		add_language_column "${TMP_CSV}"
	fi
}

# Generate the CSV file for the security.html page
function generate_security_csv() {
	TMP_CSV=${1}
	rm -f "${TMP_CSV}"

	export ODC_CSV_FILE="${REPORTS_DIR}/05__OWASP_DC/_results_extracted.csv"
	export FSB_CSV_FILE="${REPORTS_DIR}/09__FindSecBugs/_results_extracted.csv"
	export FSB_CSV="./09__FindSecBugs/_results_extracted.csv"
	export SLSCAN_CSV_FILE="${REPORTS_DIR}/11__SLSCAN/_results_extracted.csv"
	export INSIDER_CSV_FILE="${REPORTS_DIR}/12__INSIDER/_results_extracted.csv"
	export GRYPE_CSV_FILE="${REPORTS_DIR}/13__GRYPE/_results_extracted.csv"
	export TRIVY_CSV_FILE="${REPORTS_DIR}/14__TRIVY/_results_extracted.csv"
	export OSV_CSV_FILE="${REPORTS_DIR}/15__OSV/_results__security__osv.csv"
	export BEARER_CSV_FILE="${REPORTS_DIR}/17__BEARER/_results__security__bearer.csv"

	# Debug info to compare the result counts
	#echo "LANG_CSV     - $(cat $LANG_CSV | wc -l |  tr -d ' \t') entries - $LANG_CSV"
	#echo "ODC_CSV_FILE      - $(cat $ODC_CSV_FILE | wc -l |  tr -d ' \t') entries - $ODC_CSV_FILE"
	#echo "FSB_CSV_FILE      - $(cat $FSB_CSV_FILE | wc -l |  tr -d ' \t') entries - $FSB_CSV_FILE"
	#echo "SLSCAN_CSV_FILE      - $(cat $SLSCAN_CSV_FILE | wc -l |  tr -d ' \t') entries - $SLSCAN_CSV_FILE"
	#echo "INSIDER_CSV_FILE      - $(cat $INSIDER_CSV_FILE | wc -l |  tr -d ' \t') entries - $INSIDER_CSV_FILE"
	#echo "GRYPE_CSV_FILE      - $(cat $GRYPE_CSV_FILE | wc -l |  tr -d ' \t') entries - $GRYPE_CSV_FILE"
	#echo "TRIVY_CSV_FILE      - $(cat $TRIVY_CSV_FILE | wc -l |  tr -d ' \t') entries - $TRIVY_CSV_FILE"

	CSV_FILES=("${ODC_CSV_FILE}" "${FSB_CSV_FILE}" "${SLSCAN_CSV_FILE}" "${INSIDER_CSV_FILE}" "${GRYPE_CSV_FILE}" "${TRIVY_CSV_FILE}" "${OSV_CSV_FILE}" "${BEARER_CSV_FILE}")

	for CSV in "${CSV_FILES[@]}"; do
		concatenate_csv "${CSV}" "${TMP_CSV}"
	done

	if [[ -f "${TMP_CSV}" ]]; then
		add_language_column "${TMP_CSV}"
	fi
}

# Generate the CSV file for the quality.html page
function generate_quality_csv() {
	TMP_CSV=${1}
	rm -f "${TMP_CSV}"

	export ARCHEO_CSV="${REPORTS_DIR}/16__ARCHEO/_results__quality__archeo.csv"
	export PMD_CSV="${REPORTS_DIR}/07__PMD/_results_extracted.csv"
	export SCANCODE_CSV="${REPORTS_DIR}/06__SCANCODE/_results_extracted.csv"
	export MAI_CSV="${REPORTS_DIR}/10__MAI/_results_extracted.csv"

	CSV_FILES=("${ARCHEO_CSV}" "${PMD_CSV}" "${SCANCODE_CSV}" "${MAI_CSV}")

	for CSV in "${CSV_FILES[@]}"; do
		concatenate_csv "${CSV}" "${TMP_CSV}"
	done

	if [[ -f "${TMP_CSV}" ]]; then
		add_language_column "${TMP_CSV}"
	fi
}

# Generate the OWASP DC pages
function generate_owasp_dc_html() {
	export APP
	APP_LIST="${REPORTS_DIR}/00__Weave/list__all_apps.txt"
	ODC_DIR="${REPORTS_DIR}/05__OWASP_DC"
	while read -r FILE; do
		APP="$(basename "${FILE}")"
		ODC_REPORT="${ODC_DIR}/${APP}.html"
		ODC_STATS="${ODC_DIR}/${APP}_dc_report.stats"
		if [ -f "${ODC_STATS}" ]; then
			${MUSTACHE} -s="${ODC_STATS}" "${TEMPLATE_DIR}/reports/security/owasp_dc.mo" >"${ODC_REPORT}"
		fi
	done <"${APP_LIST}"
}

# Generate the FindSecBugs pages
function generate_fsb_html() {
	export APP
	APP_LIST="${REPORTS_DIR}/00__Weave/list__all_apps.txt"
	FSB_DIR="${REPORTS_DIR}/09__FindSecBugs"
	while read -r FILE; do
		APP="$(basename "${FILE}")"
		FSB_REPORT="${FSB_DIR}/${APP}.html"
		FSB_STATS="${FSB_DIR}/${APP}.stats"
		if [ -f "${FSB_STATS}" ]; then
			${MUSTACHE} -s="${FSB_STATS}" "${TEMPLATE_DIR}/reports/security/fsb.mo" >"${FSB_REPORT}"
		fi
	done <"${APP_LIST}"
}

# Generate the SLScan pages
function generate_slscan_html() {

	export APP SLSCAN_REPORT_DIR

	SLSCAN_REPORT_DIR=./../11__SLSCAN

	APP_LIST="${REPORTS_DIR}/list__tmp.txt"
	cat "${REPORTS_DIR}/00__Weave/list__java-src.txt" "${REPORTS_DIR}/00__Weave/list__python.txt" "${REPORTS_DIR}/00__Weave/list__js.txt" "${REPORTS_DIR}/00__Weave/list__cs.txt" >"${APP_LIST}"

	while read -r FILE; do
		APP="$(basename "${FILE}")"
		SLSCAN_REPORT="${REPORTS_DIR}/11__SLSCAN/${APP}.html"
		TXT_IN="${REPORTS_DIR}/11__SLSCAN/${APP}.txt"
		SLSCAN_STATS="${REPORTS_DIR}/11__SLSCAN/${APP}.stats"
		{
			${MUSTACHE} -s="${SLSCAN_STATS}" "${TEMPLATE_DIR}/reports/security/slscan_01.mo"
			echo "Tool,Critical,High,Medium,Low,Status"
			tail -n +3 "${TXT_IN}" | sed 's/║//g' | sed 's/│/,/g' | awk '{$1=$1};1' | sed 's/ , /,/g' | sed '$s/$/\`;/'
			${MUSTACHE} -s="${SLSCAN_STATS}" "${TEMPLATE_DIR}/reports/security/slscan_02.mo"
		} >"${SLSCAN_REPORT}"
	done <"${APP_LIST}"
	rm -f "${APP_LIST}"
}

# Generate the OSV pages
function generate_osv_html() {
	export APP OSV_REPORT_DIR
	OSV_REPORT_DIR=./../15__OSV

	APP_LIST="${REPORTS_DIR}/00__Weave/list__all_apps.txt"

	while read -r FILE; do
		APP="$(basename "${FILE}")"
		OSV_DIR="${REPORTS_DIR}/15__OSV"
		OSV_REPORT="${OSV_DIR}/${APP}.html"
		OSV_CSV="${OSV_DIR}/${APP}_osv.csv"
		OSV_STATS="${OSV_DIR}/${APP}_osv.stats"
		if [ -f "${OSV_CSV}" ] && [ $(wc -l <(tail -n +2 "${OSV_CSV}") | tr -d ' ' | cut -d'/' -f 1) -ne 0 ]; then
			{
				${MUSTACHE} -s="${OSV_STATS}" "${TEMPLATE_DIR}/reports/security/osv_01.mo"
				# Adding a backslash before "$" chars in the comments, replace '`' characters, close the longText const, and remove duplicated "
				sed 's/\$/\\\$/g; s/\`/"/g; s|\(java-archive\)|jar|g; s/\[\]/-/g; $s/$/\`;/; s/^""/"/g; s/^"Library,/Library,/g;' "${OSV_CSV}"
				${MUSTACHE} -s="${OSV_STATS}" "${TEMPLATE_DIR}/reports/security/osv_02.mo"
			} >"${OSV_REPORT}"
		else
			# Empty result file
			${MUSTACHE} "${TEMPLATE_DIR}/reports/security/osv_empty.mo" >"${OSV_REPORT}"
		fi
	done <"${APP_LIST}"
}

# Generate the Grype pages
function generate_grype_html() {
	export APP GRYPE_REPORT_DIR
	GRYPE_REPORT_DIR=./../13__GRYPE

	APP_LIST="${REPORTS_DIR}/00__Weave/list__all_apps.txt"

	while read -r FILE; do
		APP="$(basename "${FILE}")"
		GRYPE_DIR="${REPORTS_DIR}/13__GRYPE"
		GRYPE_REPORT="${GRYPE_DIR}/${APP}.html"
		GRYPE_CSV="${GRYPE_DIR}/${APP}_grype.csv"
		GRYPE_STATS="${GRYPE_DIR}/${APP}_grype.stats"
		if [ -f "${GRYPE_CSV}" ] && [ $(wc -l <(tail -n +2 "${GRYPE_CSV}") | tr -d ' ' | cut -d'/' -f 1) -ne 0 ]; then
			{
				${MUSTACHE} -s="${GRYPE_STATS}" "${TEMPLATE_DIR}/reports/security/grype_01.mo"
				# Adding a backslash before "$" chars in the comments, replace '`' characters, close the longText const, and remove duplicated "
				sed 's/\$/\\\$/g; s/\`/"/g; s|\(java-archive\)|jar|g; s/\[\]/-/g; $s/$/\`;/; s/^""/"/g; s/^"Library,/Library,/g;' "${GRYPE_CSV}"
				${MUSTACHE} -s="${GRYPE_STATS}" "${TEMPLATE_DIR}/reports/security/grype_02.mo"
			} >"${GRYPE_REPORT}"
		else
			# Empty result file
			${MUSTACHE} "${TEMPLATE_DIR}/reports/security/grype_empty.mo" >"${GRYPE_REPORT}"
		fi
	done <"${APP_LIST}"
}

# Build regex to transform the trivy output
function build_trivy_regex() {
	local -n URL_PATTERN_MAP=$1
	local TRIVY_REPORT_REGEX=""
	for URL_PATTERN in "${!URL_PATTERN_MAP[@]}"; do
		TRIVY_REPORT_REGEX+='s!http\([s]*://[^[:space:]]*'${URL_PATTERN}'[^[:space:]]*\)!<a href='\''TEMPTTP\1'\'' rel='\''noreferrer'\'' target='\''_blank'\''>'${URL_PATTERN_MAP[$URL_PATTERN]}'</a>!g; '
	done
	echo "${TRIVY_REPORT_REGEX}"
}

# Generate the Trivy pages
function generate_trivy_html() {

	export APP TRIVY_REPORT_DIR
	TRIVY_REPORT_DIR="./../14__TRIVY"
	TRIVY_DIR="${REPORTS_DIR}/14__TRIVY"

	APP_LIST="${REPORTS_DIR}/00__Weave/list__all_apps.txt"

	# The URL patterns are split in smaller groups because the lenght of the regex sed can handle is limited.
	# shellcheck disable=SC2034
	declare -A URL_PATTERN_MAP_1=(
		['almalinux']='Alma Linux'
		['apache.org']=Apache
		['apple']=Apple
		['bentley']=Bentley
		['bitbucket']=Bitbucket
		['bugtraq']='BugTraq'
		['chromium']=Chromium
		['cisco']=Cisco
		['contrastsecurity']=Contrast
		['cve.org']=CVE
	)

	# shellcheck disable=SC2034
	declare -A URL_PATTERN_MAP_2=(
		['cyberkendra']='CyberKendra'
		['debian']=Debian
		['eclipse.org']='Eclipse'
		['exploit-db']='Exploit DB'
		['fedora']=Fedora
		['foxglovesecurity']='FoxGlove'
		['gentoo']=Gentoo
		['github']=GitHub
		['gopivotal']='Pivotal'
		['groups.google']='Google Groups'
	)

	# shellcheck disable=SC2034
	declare -A URL_PATTERN_MAP_3=(
		['hitachi']='Hitachi'
		['hp.com']='HP'
		['hpe.com']='HPE'
		['ibm.com']='IBM'
		['ibmcloud']='IBM'
		['intel']=Intel
		['jenkins']='Jenkins'
		['jfrog.com']='JFrog'
		['jolokia.org']=Jolokia
		['jvn.jp']='JVN'
	)

	# shellcheck disable=SC2034
	declare -A URL_PATTERN_MAP_4=(
		['kb.cert.org']='CERT/CC'
		['lunasec']=LunaSec
		['mageia']='Mageia'
		['mandriva']='Mandriva'
		['marc.info']='MaRC'
		['markmail']='MarkLogic'
		['microsoft']=Microsoft
		['mitre']=MITRE
		['netapp']=NetApp
		['nist']=NIST
	)

	# shellcheck disable=SC2034
	declare -A URL_PATTERN_MAP_5=(
		['nu11secur1ty']='Nu11Secur1ty'
		['openjdk']='OpenJDK'
		['opensuse']=Suse
		['openwall']=Openwall
		['oracle']=Oracle
		['packetstorm']='Packet Storm'
		['pivotal.io']='Pivotal'
		['praetorian']='Praetorian'
		['redhat']='Red Hat'
		['rockylinux']='Rocky Linux'
	)

	# shellcheck disable=SC2034
	declare -A URL_PATTERN_MAP_6=(
		['seclists']=SecLists
		['secunia']='Secunia'
		['secpod.org']='SecPod'
		['securityfocus']='BugTraq'
		['securitytracker']='Security Tracker'
		['siemens']=Siemens
		['slackware']='Slackware'
		['snyk.io']=Snyk
		['sonicwall']=SonicWall
		['spring.io']='Spring'
	)

	# shellcheck disable=SC2034
	declare -A URL_PATTERN_MAP_7=(
		['springsource']='Spring'
		['sun.com']='Sun'
		['suse.com']='Suse'
		['tenable']=Tenable
		['trustwave']='Trustwave'
		['twitter']=Twitter
		['ubuntu']=Ubuntu
		['us-cert.gov']='CISA Gov'
		['vuldb.com']=VulDB
		['vmware']=VMware
		['zerodayinitiative']='Zero Day'
	)

	FINAL_URL_PATTERNS=(
		# Catch all remaining URLs
		's!http\([s]*://[^[:space:]]*\)!<a href='\''TEMPTTP\1'\'' rel='\''noreferrer'\'' target='\''_blank'\''>Other</a>!g'
		# Fix all processed URLs so far
		's|TEMPTTP|http|g'
		# Update the severity
		's|HIGH|High|g'
		's|MEDIUM|Medium|g'
		's|LOW|Low|g'
		's|CRITICAL|Critical|g'
		's|UNKNOWN|Unknown|g'
		# Adding a backslash before "$" chars in the comments, replace '`' characters and close the longText const
		'$s/$/\`;/'
	)

	TRIVY_PATTERNS_1=$(build_trivy_regex URL_PATTERN_MAP_1)
	TRIVY_PATTERNS_2=$(build_trivy_regex URL_PATTERN_MAP_2)
	TRIVY_PATTERNS_3=$(build_trivy_regex URL_PATTERN_MAP_3)
	TRIVY_PATTERNS_4=$(build_trivy_regex URL_PATTERN_MAP_4)
	TRIVY_PATTERNS_5=$(build_trivy_regex URL_PATTERN_MAP_5)
	TRIVY_PATTERNS_6=$(build_trivy_regex URL_PATTERN_MAP_6)
	TRIVY_PATTERNS_7=$(build_trivy_regex URL_PATTERN_MAP_7)

	for PATTERN in "${FINAL_URL_PATTERNS[@]}"; do
		TRIVY_PATTERNS_7+=";${PATTERN}"
	done

	while read -r FILE; do
		APP="$(basename "${FILE}")"
		TRIVY_REPORT="${TRIVY_DIR}/${APP}.html"
		TRIVY_CSV="${TRIVY_DIR}/${APP}_trivy.csv"
		TRIVY_STATS="${TRIVY_DIR}/${APP}_trivy.stats"
		TRIVY_TMP="${TRIVY_DIR}/${APP}_trivy.tmp"

		if [ $(wc -l <(tail -n +2 "${TRIVY_CSV}") | tr -d ' ' | cut -d'/' -f 1) -eq 0 ]; then
			# Empty result file
			${MUSTACHE} "${TEMPLATE_DIR}/reports/security/trivy_empty.mo" >"${TRIVY_REPORT}"
		else
			sed 's/\$/\\\$/g; s/\`/"/g; s|\(java-archive\)|jar|g; s/^""/"/g; s/^"Library,/Library,/g; s#\(http[s]*://\)# \1#g' "${TRIVY_CSV}" | tr -s ' ' >"${TRIVY_TMP}"
			stream_edit "${TRIVY_PATTERNS_1}" "${TRIVY_TMP}"
			stream_edit "${TRIVY_PATTERNS_2}" "${TRIVY_TMP}"
			stream_edit "${TRIVY_PATTERNS_3}" "${TRIVY_TMP}"
			stream_edit "${TRIVY_PATTERNS_4}" "${TRIVY_TMP}"
			stream_edit "${TRIVY_PATTERNS_5}" "${TRIVY_TMP}"
			stream_edit "${TRIVY_PATTERNS_6}" "${TRIVY_TMP}"
			stream_edit "${TRIVY_PATTERNS_7}" "${TRIVY_TMP}"
			{
				${MUSTACHE} -s="${TRIVY_STATS}" "${TEMPLATE_DIR}/reports/security/trivy_01.mo"
				cat "${TRIVY_TMP}"
				${MUSTACHE} -s="${TRIVY_STATS}" "${TEMPLATE_DIR}/reports/security/trivy_02.mo"
			} >"${TRIVY_REPORT}"
		fi
		rm -f "${TRIVY_TMP}" "${TRIVY_TMP}-e"
	done <"${APP_LIST}"
}

# Generate the Archeo pages
function generate_archeo_html() {

	export APP ARCHEO_REPORT_DIR
	ARCHEO_REPORT_DIR=./../16__ARCHEO

	APP_LIST="${REPORTS_DIR}/00__Weave/list__all_apps.txt"

	while read -r FILE; do
		APP="$(basename "${FILE}")"
		ARCHEO_DIR="${REPORTS_DIR}/16__ARCHEO"
		ARCHEO_REPORT="${ARCHEO_DIR}/${APP}.html"
		ARCHEO_STATS="${ARCHEO_DIR}/${APP}_archeo_findings.stats"
		ARCHEO_CSV="${ARCHEO_DIR}/${APP}_archeo_findings.csv"
		if [ -f "${ARCHEO_CSV}" ] && [ $(wc -l <(tail -n +2 "${ARCHEO_CSV}") | tr -d ' ' | cut -d'/' -f 1) -ne 0 ]; then
			{
				${MUSTACHE} -s="${ARCHEO_STATS}" "${TEMPLATE_DIR}/reports/quality/archeo_01.mo"
				# Adding a backslash before "$" chars in the comments, replace '`' characters, close the longText const, and remove duplicated "
				sed 's/\$/\\\$/g; s/\`/"/g; s/\[\]/-/g; $s/$/\`;/; s/^""/"/g; ' "${ARCHEO_CSV}"
				${MUSTACHE} -s="${ARCHEO_STATS}" "${TEMPLATE_DIR}/reports/quality/archeo_02.mo"
			} >"${ARCHEO_REPORT}"
		else
			# Empty result file
			${MUSTACHE} "${TEMPLATE_DIR}/reports/quality/archeo_empty.mo" >"${ARCHEO_REPORT}"
		fi
	done <"${APP_LIST}"

}

# Generate all pages
function generate_reports() {

	LINK_REPORT="${REPORTS_DIR}/index.html"
	CLOUD_REPORT="${REPORTS_DIR}/cloud.html"
	SECURITY_REPORT="${REPORTS_DIR}/security.html"
	QUALITY_REPORT="${REPORTS_DIR}/quality.html"
	INFO_RULES_REPORT="${REPORTS_DIR}/info_rules.html"

	# Export all variables for the reports
	export_vars

	# Generate overview report (index)
	${MUSTACHE} "${TEMPLATE_DIR}/reports/index.mo" >"${LINK_REPORT}"
	log_console_success "Open this file for reviewing all generated reports: ${LINK_REPORT}"

	# Generate cloud report
	if [[ "${HAS_CLOUD_REPORT}" == TRUE ]]; then

		# Generate CSV file with all results
		generate_cloud_csv "${CLOUD_TMP_CSV}"

		RESULT_REPORT_MAP="${REPORTS_DIR}/03__WINDUP/_report_map.js"

		# Generate cloud HTML file
		{
			${MUSTACHE} "${TEMPLATE_DIR}/reports/cloud_01.mo"
			echo 'const longText = `'\\
			cat "${CLOUD_TMP_CSV}"
			echo '`;'
			[[ -f "${RESULT_REPORT_MAP}" ]] && cat "${RESULT_REPORT_MAP}"
			${MUSTACHE} "${TEMPLATE_DIR}/reports/cloud_02.mo"
		} >"${CLOUD_REPORT}"

		#rm -f "${RESULT_REPORT_MAP}"
		log_console_info "Open this file for reviewing all generated reports: ${CLOUD_REPORT}"
	fi

	# Generate security reports
	if [[ "${HAS_SECURITY_REPORT}" == TRUE ]]; then

		# Generate CSV file with all results
		generate_security_csv "${SECURITY_TMP_CSV}"

		if [[ "${HAS_ODC_REPORT}" == TRUE ]]; then
			generate_owasp_dc_html
		fi

		if [[ "${HAS_FSB_REPORT}" == TRUE ]]; then
			generate_fsb_html
		fi

		if [[ "${HAS_SLSCAN_REPORT}" == TRUE ]]; then
			generate_slscan_html
		fi

		if [[ "${HAS_GRYPE_REPORT}" == TRUE ]]; then
			generate_grype_html
		fi

		if [[ "${HAS_TRIVY_REPORT}" == TRUE ]]; then
			generate_trivy_html
		fi

		if [[ "${HAS_OSV_REPORT}" == TRUE ]]; then
			generate_osv_html
		fi

		if [[ -f "${SECURITY_TMP_CSV}" ]]; then
			export HAS_SECURITY_REPORT_TABLE=TRUE
			# Generate security HTML file with table
			{
				${MUSTACHE} "${TEMPLATE_DIR}/reports/security_01.mo"
				echo 'const longText = `'\\
				cat "${SECURITY_TMP_CSV}"
				echo '`;'
				${MUSTACHE} "${TEMPLATE_DIR}/reports/security_02.mo"
			} >"${SECURITY_REPORT}"
		else
			export HAS_SECURITY_REPORT_TABLE=''
			# Generate security HTML file without table
			{
				${MUSTACHE} "${TEMPLATE_DIR}/reports/security_01.mo"
			} >"${SECURITY_REPORT}"
		fi

		log_console_info "Open this file for reviewing all generated reports: ${SECURITY_REPORT}"
	fi

	# Generate quality reports
	if [[ "${HAS_QUALITY_REPORT}" == TRUE ]]; then

		# Generate CSV file with all results
		generate_quality_csv "${QUALITY_TMP_CSV}"

		if [[ "${HAS_ARCHEO_REPORT}" == TRUE ]]; then
			generate_archeo_html
		fi

		if [[ -f "${QUALITY_TMP_CSV}" ]]; then
			# Generate quality HTML file
			{
				${MUSTACHE} "${TEMPLATE_DIR}/reports/quality_01.mo"
				echo 'const longText = `'\\
				cat "${QUALITY_TMP_CSV}"
				echo '`;'
				${MUSTACHE} "${TEMPLATE_DIR}/reports/quality_02.mo"
			} >"${QUALITY_REPORT}"
			log_console_info "Open this file for reviewing all generated reports: ${QUALITY_REPORT}"
		else
			log_console_error "Quality file missing: ${QUALITY_TMP_CSV}"
		fi
	fi

	# shellcheck source=/dev/null
	source "${DIST_DIR}/rules.counts"
	export ARCHEO_RULES CSA_RULES CLOC_RULES FSB_RULES GRYPE_RULES INSIDER_RULES LINGUIST_RULES MAI_RULES ODC_RULES OSV_RULES BEARER_RULES PMD_RULES SCANCODE_RULES SLSCAN_RULES TRIVY_RULES WAMT_RULES WINDUP_RULES
	${MUSTACHE} "${TEMPLATE_DIR}/reports/info/info_rules.mo" >"${INFO_RULES_REPORT}"

	# Merging all results in one summary CSV file (${SUMMARY_CSV})
	rm -f "${SUMMARY_CSV}"
	touch "${SUMMARY_CSV}"

	if [[ -f "${CLOUD_TMP_CSV}" ]]; then
		cp -f "${CLOUD_TMP_CSV}" "${SUMMARY_CSV}"
	fi

	if [[ -f ${SECURITY_TMP_CSV} ]]; then
		if [[ -f "${SUMMARY_CSV}" ]]; then
			paste -d "${SEPARATOR}" "${SUMMARY_CSV}" <(cut -d "${SEPARATOR}" -f3- "${SECURITY_TMP_CSV}") >>"${SUMMARY_CSV}.tmp"
			mv "${SUMMARY_CSV}.tmp" "${SUMMARY_CSV}"
		else
			cp -f "${SECURITY_TMP_CSV}" "${SUMMARY_CSV}"
		fi
	fi

	if [[ -f ${QUALITY_TMP_CSV} ]]; then
		if [[ -f "${SUMMARY_CSV}" ]]; then
			paste -d "${SEPARATOR}" "${SUMMARY_CSV}" <(cut -d "${SEPARATOR}" -f3- "${QUALITY_TMP_CSV}") >>"${SUMMARY_CSV}.tmp"
			mv "${SUMMARY_CSV}.tmp" "${SUMMARY_CSV}"
		else
			cp -f "${QUALITY_TMP_CSV}" "${SUMMARY_CSV}"
		fi
	fi

	rm -f "${CLOUD_TMP_CSV}" "${SECURITY_TMP_CSV}" "${QUALITY_TMP_CSV}"

	mv "${SUMMARY_CSV}" "${SUMMARY_CSV_FULL_NAME}"
}

# Generate HTML file vizualising the CLOC and Linguist results
function generate_language_report() {

	export APP_DATE LANGUAGES_REPORT HEIGHT LINGUIST_CSV CLOC_CSV LANGUAGES_LOG
	CLOC_CSV="./08__LINGUIST/_CLOC_results_extracted.csv"
	LINGUIST_CSV="./08__LINGUIST/_LINGUIST_results_extracted.csv"
	OUTPUT_CLOC_FILE="${REPORTS_DIR}/08__LINGUIST/_CLOC_results_generated.txt"
	OUTPUT_LINGUIST_FILE="${REPORTS_DIR}/08__LINGUIST/_LINGUIST_results_generated.txt"
	LANGUAGES_LOG="./08__LINGUIST.log"

	if [[ -f "${OUTPUT_LINGUIST_FILE}" && -f "${OUTPUT_CLOC_FILE}" ]]; then

		APP_DATE="$(echo "${TIMESTAMP}" | cut -d'_' -f 1-3 | sed 's/_/./g') at $(echo "${TIMESTAMP}" | cut -d'_' -f 5-7 | sed 's/_/:/g')"

		LANGUAGES_REPORT="${REPORTS_DIR}/languages.html"
		# HEIGHT: LINES x23 + 40
		APPS=$(uniq <"${OUTPUT_LINGUIST_FILE}" | wc -l)
		CALCULATED_HEIGHT=$(((APPS - 2) * 23 + 40))
		HEIGHT=$((450 > CALCULATED_HEIGHT ? 450 : CALCULATED_HEIGHT))

		# Header
		${MUSTACHE} "${TEMPLATE_DIR}/reports/languages_01.mo" >"${LANGUAGES_REPORT}"
		# Append prepared data
		{
			echo 'const longTextCloc = `'\\
			cat "${OUTPUT_CLOC_FILE}"
			echo '`;' >>"${LANGUAGES_REPORT}"
			echo 'const longTextLinguist = `'\\
			cat "${OUTPUT_LINGUIST_FILE}"
			echo '`;'
		} >>"${LANGUAGES_REPORT}"
		# Footer
		${MUSTACHE} "${TEMPLATE_DIR}/reports/languages_02.mo" >>"${LANGUAGES_REPORT}"
		log_console_info "Open this file for reviewing all generated reports: ${LANGUAGES_REPORT}"

	fi
}

# Generate HTML file linking all reports
function main() {
	mkdir -p "${APP_DIR_IN}"
	mkdir -p "${REPORTS_DIR}"
	cp -Rfp "${TEMPLATE_DIR}/static" "${REPORTS_DIR}/."

	export APP_DATE LINK_REPORT CSA_LOG REPORT_TIMESTAMP
	APP_DATE="$(echo "${TIMESTAMP}" | cut -d'_' -f 1-3 | sed 's/_/./g') at $(echo "${TIMESTAMP}" | cut -d'_' -f 5-7 | sed 's/_/:/g')"
	CSA_LOG="./02__CSA.log"
	export REPORT_TIMESTAMP=$(date +%Y.%m.%d\ at\ %H:%M:%S)

	generate_reports
	generate_language_report

	log_console_info "Results: ${SUMMARY_CSV}"

}

main
