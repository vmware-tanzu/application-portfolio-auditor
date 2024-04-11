#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all EAR, WAR, JAR binary applications in ${APP_DIR_IN} grouped in sub-folders using ...
#   "Find Security Bugs" - https://find-sec-bugs.github.io/
##############################################################################################################

# ------ Do not modify
VERSION="${FSB_VERSION}"
STEP=$(get_step)

APP_DIR_OUT="${REPORTS_DIR}/${STEP}__FindSecBugs"
LOG_FILE="${APP_DIR_OUT}".log

LIST_JAVA_BIN="${REPORTS_DIR}/00__Weave/list__java-bin.txt"

# Analyze all applications present in the ${APP_GROUP_DIR} directory.
function analyze() {
	if [[ -s "${LIST_JAVA_BIN}" ]]; then
		while read -r APP; do
			APP_NAME=$(basename "${APP}")
			APP_DIR=$(dirname "${APP}")
			log_analysis_message "app '${APP_NAME}'"

			# Prevent crash for empty applications
			set +e
			ARGS=(
				-low
				-html
				-output "/out/${APP_NAME}.html"
				"/apps/${APP_NAME}"
			)
			(time ${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm -v "${APP_DIR}:/apps:ro" -v "${APP_DIR_OUT}:/out:delegated" --name FSB "${CONTAINER_IMAGE_NAME_FSB}" "${ARGS[@]}" 2> >(grep -v "^SLF4J")) >>"${LOG_FILE}" 2>&1
			set -e
		done <"${LIST_JAVA_BIN}"
		log_console_success "Open this directory for the results: ${APP_DIR_OUT}"
	else
		log_console_warning "No binary Java application found. Skipping FindSecBug analysis."
	fi
}

function main() {
	log_tool_info "Find Security Bugs (FSB) v${VERSION}"
	if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_FSB}") ]]; then
		mkdir -p "${APP_DIR_OUT}"
		analyze
	else
		log_console_error "FSB analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_FSB_FSB}'"
	fi
}

main
