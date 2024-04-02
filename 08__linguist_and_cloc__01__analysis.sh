#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all binary applications (EAR/WAR/JAR) in ${APP_DIR_IN} grouped in sub-folders using ...
#   "GitHub Linguist" - https://github.com/github/linguist
#      Library used on GitHub.com to detect blob languages, ignore binary or vendored files,
#      suppress generated files in diffs, and generate language breakdown graphs.
#
#   "Count Lines of Code" (CLOC) - https://github.com/AlDanial/cloc
#      Counts blank lines, comment lines, and physical lines of source code in many programming languages.
##############################################################################################################

# ----- Please adjust

# Ignore files which take more than <CLOC_TIMEOUT> seconds to process. Tool default is 10 seconds.
# Setting <CLOC_TIMEOUT> to 0 allows unlimited time.  (Large files with many repeated lines can cause Algorithm::Diff::sdiff() to take hours.)
CLOC_TIMEOUT=30

# ------ Do not modify
VERSION=${LINGUIST_VERSION}
STEP=$(get_step)

export APP_DIR_OUT="${REPORTS_DIR}/${STEP}__LINGUIST"
export LOG_FILE="${APP_DIR_OUT}.log"

function linguist() {
	LANG_FILE="${1}"
	REPO="${2}"
	REPO_NAME="${3}"
	LOG_FILE="${4}"
	if [ ! -f "${LANG_FILE}" ]; then
		if [ -d "${REPO}" ]; then
			# Transforms repo in a git repository to avoid linguist to crash.
			if [ ! -d "${REPO}/.git" ]; then
				log_console_step "git init (${REPO_NAME})"
				set +e
				pushd "${REPO}" &>/dev/null
				git config --global init.defaultBranch master
				git init . >/dev/null
				git add -A >/dev/null
				git config user.name "ARG"
				git config user.email "ARG@VMWARE.COM"
				git commit -m 'init' >/dev/null
				popd &>/dev/null
				set -e
			fi
			log_console_step "linguist (${REPO_NAME})"

			set +e
			${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} -t --rm -v "${REPO}:/repo:ro" "${CONTAINER_IMAGE_NAME_LINGUIST}" >"${LANG_FILE}" 2>&1 | tee -a "${LOG_FILE}"
			set -e
		fi
	fi
}

function analyze_dir() {

	DIR="${1}"
	REPO_NAME=$(basename "${DIR}")
	REPO="${APP_GROUP_SRC_DIR}/${REPO_NAME}"
	LINGUIST_FILE="${APP_DIR_OUT}/${REPO_NAME}.linguist"
	CLOC_RESULTS="${APP_DIR_OUT}/${REPO_NAME}.cloc"

	# Run Linguist
	linguist "${LINGUIST_FILE}" "${REPO}" "${REPO_NAME}" "${LOG_FILE}"

	# Run CLOC
	log_console_step "cloc (${REPO_NAME})"

	set +e
	${CONTAINER_ENGINE} run --rm -v "${DIR}:/repo:ro" "${CONTAINER_IMAGE_NAME_CLOC}" "/repo" --csv --diff-timeout "${CLOC_TIMEOUT}" --timeout "${CLOC_TIMEOUT}" --hide-rate --quiet >"${CLOC_RESULTS}"
	set -e

	# Parsing CLOC results
	PART1=$(grep 'SUM' <"${CLOC_RESULTS}" | awk -F "," -v repo="${REPO_NAME}" -v group="${APP_GROUP}" '{printf("%s;%s;%s;%s;%s;%s", group, repo, $1, $3, $4, $5)}' 2>&1 | tee -a "${LOG_FILE}")
	# Parsing Linguist results
	PART2=$(awk '{printf("%s\t%s\n", $3, $1)}' "${LINGUIST_FILE}" | tr "\r\n\t " ';' | sed -e "s/;;*/;/g" 2>&1 | tee -a "${LOG_FILE}")
	# Parsing CLOC results (bis)
	PART3=$(tail -n +3 <"${CLOC_RESULTS}" | grep -v ",SUM," | awk -F "," '{printf("%s;%s;", $2, $5)}' | awk -F "," -v repo="${REPO_NAME}" -v group="${APP_GROUP}" '{printf("%s;%s;%s", group, repo, $1)}' | tr ' ' '_')

	if [[ ${PART1} == *"${REPO_NAME}"* ]]; then
		echo "${PART1};${PART2}" >>"${OUT_CSV_FILE}"
		echo "${PART3}" >>"${OUT_CLOC_CSV_FILE}"
	fi

}

function main() {
	log_tool_info "Linguist v${VERSION} & CLOC v${CLOC_VERSION}"
	if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_LINGUIST}") ]]; then
		if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_CLOC}") ]]; then
			export OUT_CSV_FILE=${APP_DIR_OUT}/../${STEP}__LOC__LINGUIST__results_extracted.csv
			export OUT_CLOC_CSV_FILE=${APP_DIR_OUT}/../${STEP}__LOC__CLOC__results_extracted.csv

			rm -Rf "${APP_DIR_OUT}"
			mkdir -p "${APP_DIR_OUT}"
			rm -f "${OUT_CSV_FILE}" "${OUT_CLOC_CSV_FILE}"

			# Analyze all applications present in the ${APP_GROUP_DIR} directory.
			while read -r DIR; do
				analyze_dir "${DIR}"
			done <"${REPORTS_DIR}/list__${APP_GROUP}__all_apps.txt"

			log_console_success "Results: ${OUT_CSV_FILE}"
		else
			log_console_error "Linguist analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_CLOC}'"
		fi
	else
		log_console_error "Linguist analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_LINGUIST}'"
	fi
}

main
