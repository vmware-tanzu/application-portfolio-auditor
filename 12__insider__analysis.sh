#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all source applications in ${APP_DIR_IN} grouped in sub-folders using ...
#   "INSIDER Static Application Security Testing" (SAST) - https://github.com/insidersec/insider & https://insidersec.io/
#
# Static Application Security Testing (SAST) engine focused on covering the OWASP Top 10, to make source code analysis to find vulnerabilities right in the source code, focused on a agile and easy to implement software inside your DevOps pipeline.
##############################################################################################################

# ----- Please adjust

# ------ Do not modify
VERSION=${INSIDER_VERSION}
STEP=$(get_step)

APP_BASE=${REPORTS_DIR}/${STEP}__INSIDER
export LOG_FILE="${APP_BASE}.log"

ANALYZABLE_APP_FOUND="false"

# Analyse all applications present in provided list.
function analyze() {

	LANGUAGE=${1}
	APP_LIST=${2}

	if [[ -s "${APP_LIST}" ]]; then
		while read -r APP; do
			APP_NAME=$(basename "${APP}")
			log_analysis_message "app (${LANGUAGE}) '${APP_NAME}'"

			# Run INSIDER
			set +e
			## Analyze all source files in the ${APP_DIR_TMP} directory.
			#${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm -v "${APP}:/${APP_NAME}" insidersec/insider -tech java -target "/${APP_NAME}"

			OUT_DIR="${APP_DIR_OUT}/${APP_NAME}"
			mkdir -p "${OUT_DIR}"

			## Hack to analyze and copy the reports from the execution
			### Note 1: The provided container image does not run on Linux ARM64 ("exec format error")
			### Note 2: The severity is not displayed properly in the HTML reports (https://github.com/insidersec/insider/issues/57)
			${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm -v "${APP}:/${APP_NAME}" -v "${OUT_DIR}:/opt/reports" --entrypoint '/bin/sh' insidersec/insider -c "cd /opt/insider; ./insider -tech ${LANGUAGE} -target /${APP_NAME}; cp report.html report.json style.css /opt/reports/." >>"${LOG_FILE}" 2>&1

			# Hack to fix the issue with files created with root user
			if sudo -n ls >/dev/null 2>&1; then
				sudo chown -R "$(id -u):$(id -g)" "${APP_DIR_OUT}"
			fi
			set -e

			REPORT_HTML="${OUT_DIR}/report.html"
			if [ -f "${REPORT_HTML}" ]; then
				ANALYZABLE_APP_FOUND="true"
				mv "${REPORT_HTML}" "${OUT_DIR}_report.html"
				mv "${OUT_DIR}/report.json" "${OUT_DIR}_report.json"

				REPORT_CSS="${OUT_DIR}/style.css"
				if [ -f "${REPORT_CSS}" ]; then
					cp -fp "${REPORT_CSS}" "${APP_DIR_OUT}/style.css"
				fi
			fi

			rm -Rf "${OUT_DIR}"
		done <"${APP_LIST}"
	fi
}

# Analyse all applications present in the ${1} directory.
function analyze_group() {
	GROUP=$(basename "${1}")
	log_analysis_message "group '${GROUP}'"

	export APP_DIR_OUT="${APP_BASE}__${GROUP}"
	mkdir -p "${APP_DIR_OUT}"

	analyze java "${REPORTS_DIR}/list__${GROUP}__java-src.txt"
	analyze csharp "${REPORTS_DIR}/list__${GROUP}__cs.txt"

	if [[ "${ANALYZABLE_APP_FOUND}" == "true" ]]; then
		log_console_success "Open this directory for the results: ${APP_DIR_OUT}"
	else
		log_console_warning "No suitable app found. Skipping INSIDER analysis."
	fi
}

function main() {

	if [[ "${DEBUG}" == "true" ]]; then
		set -x
		exec 6>&1
	else
		exec 6>/dev/null
	fi

	log_tool_info "Insider Static Application Security Testing (SAST) v${VERSION}"

	if [[ -n "$(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_INSIDER}")" ]]; then
		for_each_group analyze_group
	else
		log_console_error "INSIDER analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_INSIDER}'"
	fi

}

main
