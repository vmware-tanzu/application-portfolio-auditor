#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all EAR, WAR, JAR binary applications in ${APP_DIR_IN} grouped in sub-folders using ...
#   "Microsoft Application Inspector" - https://github.com/microsoft/ApplicationInspector
#
# "Microsoft Application Inspector" is a source code analyzer built for surfacing features of interest and other characteristics
# to answer the question 'what's in it' using static analysis with a json based rules engine. Ideal for scanning components before use or detecting feature level changes.
##############################################################################################################

# ----- Please adjust

# ------ Do not modify
VERSION=${MAI_VERSION}

STEP=$(get_step)
APP_DIR_OUT=${REPORTS_DIR}/${STEP}__MAI
export LOG_FILE=${APP_DIR_OUT}.log

# Analyze all applications present in the ${APP_GROUP_DIR} directory.
function analyze() {
	while read -r APP; do
		set +e
		APP_NAME=$(basename "${APP}")
		log_analysis_message "app '${APP_NAME}'"
		MAI_OUT=${APP_DIR_OUT}/mai__${APP_GROUP}__${APP_NAME}

		if [[ -f "${APP}" || -d "${APP}" ]]; then
			APP_DIR=$(dirname "${APP}")
			# shellcheck disable=SC2054
			ARGS=(
				analyze
				--no-show-progress
				--source-path "/apps/${APP_NAME}"
				--log-file-level Information
				--console-verbosity Information
				--confidence-filters High,Medium
				--exclusion-globs '**/bin/**,**/lib/**,**/.vs/**,**/.git/**,**/.idea/**'
				--output-file-format html
				--context-lines 0
			)
			set +e

			mkdir -p "${MAI_OUT}"
			(time ${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm -v "${APP_DIR}:/apps:ro" -v "${MAI_OUT}:/out:delegated" --name MAI "${CONTAINER_IMAGE_NAME_MAI}" "${ARGS[@]}") >>"${LOG_FILE}" 2>&1

			# Hack to fix the issue with files created with root user
			if sudo -n ls >/dev/null 2>&1; then
				sudo chown -R "$(id -u):$(id -g)" "${MAI_OUT}"
			fi
			set -e

			OUTPUT_HTML="${MAI_OUT}/output.html"
			if [ -f "${OUTPUT_HTML}" ]; then
				mv "${OUTPUT_HTML}" "${MAI_OUT}.html"
			fi
			if [ ! -d "${APP_DIR_OUT}/html" ] && [ -d "${MAI_OUT}/html" ]; then
				mv "${MAI_OUT}/html" "${APP_DIR_OUT}/html"
			fi
			rm -Rf "${MAI_OUT}"
		fi
		set -e
	done <"${REPORTS_DIR}/list__${APP_GROUP}__all_apps.txt"
}

function main() {
	log_tool_info "Microsoft Application Inspector (MAI) v${VERSION}"
	mkdir -p "${APP_DIR_OUT}"
	analyze
	log_console_success "Open this directory for the results: ${APP_DIR_OUT}"
}

main
