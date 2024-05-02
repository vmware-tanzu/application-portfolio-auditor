#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Checks the generated reports
##############################################################################################################

# Directories
REPORT_FOLDER="$(dirname "${BASH_SOURCE[0]}")/../../reports"

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
BLUE='\033[0;36m'
NORMAL='\033[0m'
BOLD='\033[1m'

readonly REPORT_FOLDER GREEN RED ORANGE BLUE NORMAL

function display_duration() {
	local TOTAL_HOURS=0
	local TOTAL_MINUTES=0
	local TOTAL_SECONDS=0

	while read -r FILE; do
		REPORT_DIR="$(basename "$(dirname "${FILE}")")"
		APP_GROUP=$(basename "${REPORT_DIR}" | rev | cut -d '_' -f 1 | rev)
		TIMESTAMP=$(basename "${REPORT_DIR}" | rev | cut -d '_' -f 3- | rev)
		echo "[${TIMESTAMP}] ${APP_GROUP} - ${FILE}"
		TMP_FILE="${REPORT_FOLDER}/tmp"

		# Extract first and last non empty lines
		grep -v '^[[:space:]]*$' "${FILE}" | sed -e 1b -e '$!d' >"${TMP_FILE}"

		line1=$(grep -o '\[[0-9_]*\]' "${TMP_FILE}" | sed -n 1p)
		line2=$(grep -o '\[[0-9_]*\]' "${TMP_FILE}" | sed -n 2p)

		if [[ -n "${line1}" ]] && [[ -n "${line2}" ]]; then
			# Extract formatted date strings
			date_str1=$(echo " ${line1}" | awk -F'[_\\[\\]]' '{print $2"-"$3"-"$4"__"$6"_"$7"_"$8}')
			date_str2=$(echo " ${line2}" | awk -F'[_\\[\\]]' '{print $2"-"$3"-"$4"__"$6"_"$7"_"$8}')

			if [[ -n "${date_str1}" ]] && [[ -n "${date_str2}" ]]; then
				# Convert formatted dates to UNIX timestamps
				timestamp1=$(date -j -f "%Y-%m-%d__%H_%M_%S" "${date_str1}" "+%s")
				timestamp2=$(date -j -f "%Y-%m-%d__%H_%M_%S" "${date_str2}" "+%s")

				# Calculate the time difference in seconds
				time_difference=$((timestamp2 - timestamp1))

				# Calculate hours, minutes, and seconds
				HOURS=$((time_difference / 3600))
				MINUTES=$(((time_difference % 3600) / 60))
				SECONDS=$((time_difference % 60))

				# Print the result
				echo -e "  >>> ${GREEN}Duration: $HOURS hours, $MINUTES minutes, $SECONDS seconds${NORMAL} - ${BLUE}$(dirname "${FILE}")/index.html${NORMAL}"
				((TOTAL_HOURS += HOURS))
				((TOTAL_MINUTES += MINUTES))
				((TOTAL_SECONDS += SECONDS))

			else
				echo -e "  >>> ${RED}No time data found${NORMAL} - ${BLUE}$(dirname "${FILE}")/index.html${NORMAL}"
			fi
		else
			echo -e "  >>> ${RED}No time data found${NORMAL} - ${BLUE}$(dirname "${FILE}")/index.html${NORMAL}"
		fi

		rm -f "${TMP_FILE}"

	done < <(find "${REPORT_FOLDER}" -mindepth 2 -maxdepth 2 -type f -name '*_timeline.log' | sort -f)

	# Convert total seconds to minutes and add to total minutes
	(("TOTAL_MINUTES += TOTAL_SECONDS / 60"))

	# Calculate remaining seconds after converting to minutes
	(("TOTAL_SECONDS %= 60"))

	# Convert total minutes to hours and add to total hours
	(("TOTAL_HOURS += TOTAL_MINUTES / 60"))

	# Calculate remaining minutes after converting to hours
	(("TOTAL_MINUTES %= 60"))

	echo ""
	echo -e "Total time: ${ORANGE}$TOTAL_HOURS hours, $TOTAL_MINUTES minutes, $TOTAL_SECONDS seconds${NORMAL}"
}

function analyze_logs() {

	while read -r REPORT_DIR; do
		APP_GROUP=$(basename "${REPORT_DIR}" | rev | cut -d '_' -f 1 | rev)
		TIMESTAMP=$(basename "${REPORT_DIR}" | rev | cut -d '_' -f 3- | rev)
		echo -e "[${TIMESTAMP}] ${APP_GROUP}"
		while read -r FSB_LOG; do
			if grep -q '^Out of memory' "${FSB_LOG}"; then
				echo -e "  >>>  ${RED}FindSecBugs - 'Out of memory' error detected${NORMAL} - ${FSB_LOG}"
			fi
		done < <(find "${REPORT_DIR}" -mindepth 1 -maxdepth 1 -type f -name '*FindSecBugs*.log')

	done < <(find "${REPORT_FOLDER}" -mindepth 1 -maxdepth 1 -type d -name '20*' | sort -f)
}

function analyze_html() {

	while read -r REPORT_DIR; do

		APP_GROUP=$(basename "${REPORT_DIR}" | rev | cut -d '_' -f 1 | rev)
		TIMESTAMP=$(basename "${REPORT_DIR}" | rev | cut -d '_' -f 3- | rev)
		echo -e "[${TIMESTAMP}] ${APP_GROUP}"

		while read -r FILE; do
			echo -e "  >>>  Analyzing '${FILE}'"
			vnu --errors-only "${FILE}"
		done < <(find "${REPORT_DIR}" "${REPORT_DIR}/13__GRYPE" "${REPORT_DIR}/11__SLSCAN" "${REPORT_DIR}/14__TRIVY" "${REPORT_DIR}/15__OSV" "${REPORT_DIR}/16__ARCHEO" -mindepth 1 -maxdepth 1 -type f -name '*.html')

		while read -r FILE; do
			echo -e "  >>>  Analyzing '${FILE}'"
			vnu --errors-only "${FILE}"
		done < <(find "${REPORT_DIR}/05__OWASP_DC" -mindepth 1 -maxdepth 1 -type f -name '*.html' ! -name '*_dc_report.html' )

		while read -r FILE; do
			echo -e "  >>>  Analyzing '${FILE}'"
			vnu --errors-only "${FILE}"
		done < <(find "${REPORT_DIR}/09__FindSecBugs" -mindepth 1 -maxdepth 1 -type f -name '*.html' ! -name '*_fsb.html' )

		while read -r FILE; do
			echo -e "  >>>  Analyzing '${FILE}'"
			vnu --errors-only "${FILE}"
		done < <(find "${REPORT_DIR}/12__INSIDER" -mindepth 1 -maxdepth 1 -type f -name '*.html' ! -name '*_report.html' )

		while read -r FILE; do
			echo -e "  >>>  Analyzing '${FILE}'"
			vnu --errors-only "${FILE}"
		done < <(find "${REPORT_DIR}/17__BEARER" -mindepth 1 -maxdepth 1 -type f -name '*.html' ! -name '*_bearer.html' )

	done < <(find "${REPORT_FOLDER}" -mindepth 1 -maxdepth 1 -type d -name '20*' | sort -f)
}

function main() {
	echo -e "${BOLD}Duration${NORMAL}\n"
	display_duration

	echo -e "\n${BOLD}Logs${NORMAL}\n"
	analyze_logs

	if [[ -n "$(command -v vnu)" ]]; then
		echo -e "\n${BOLD}HTML reports${NORMAL}\n"
		analyze_html
	fi
}

main
