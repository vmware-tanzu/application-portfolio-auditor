#!/usr/bin/env bash
# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all applications in ${APP_DIR_IN} grouped in sub-folders using ...
#   "Trivy" - https://trivy.dev/
#
# "Trivy" is an all-in-one open source security scanner.
##############################################################################################################

# ----- Please adjust

# ------ Do not modify
VERSION=${TRIVY_VERSION}
STEP=$(get_step)
CONTAINER_IMAGE_NAME_TRIVY="trivy:${TRIVY_VERSION}"
TRIVY_VULN_CACHE_DIR="${DIST_DIR}/trivy_cache"
TRIVY_OFFLINE_ARGS=()

export LOG_FILE=${REPORTS_DIR}/${STEP}__TRIVY.log

# Analyse all applications present in provided list.
function analyze() {

	APP_LIST=${1}
	if [[ -s "${APP_LIST}" ]]; then
		while read -r APP; do
			APP_NAME=$(basename "${APP}")
			APP_FOLDER=$(dirname "${APP}")
			log_analysis_message "app '${APP_NAME}'"

			set +e

			PREFIX=""
			if [[ -f "${APP}" ]]; then
				PREFIX="rootfs"
			elif [[ -d "${APP}" ]]; then
				PREFIX="filesystem"
			fi

			APP_NAME_SHORT="${APP_NAME}"
			if [[ "${APP_NAME}" == *\.zip ]]; then
				APP_NAME_SHORT="${APP_NAME%.*}"
			fi

			if [[ -z "${PREFIX}" ]]; then
				log_console_error "Invalid application: '${APP}'"
			else
				#set -x
				${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm \
					-v "${OUT_DIR}:/out:delegated" -v "${APP_FOLDER}:/src:ro" -v "${DIST_DIR}/templating:/tmpl:ro" \
					"${CONTAINER_IMAGE_NAME_TRIVY}" "${PREFIX}" \
					-f template --template "@/tmpl/trivy_csv.tpl" -o "/out/${APP_NAME_SHORT}_trivy.tmp" \
					--no-progress --scanners "vuln,config,secret,license" \
					--debug --skip-db-update --skip-java-db-update --offline-scan "/src/${APP_NAME}" 2>>"${LOG_FILE}"
				#set +x
				OUT_FILE="${OUT_DIR}/${APP_NAME_SHORT}_trivy"
				sed 's/"/\x27\x27/g; s/`/\x27/g; s/____/"/g' "${OUT_FILE}.tmp" >"${OUT_FILE}.csv"
				rm -f "${OUT_FILE}.tmp"
			fi

			set -e
		done <"${APP_LIST}"
	fi
}

# Analyse all applications present in the ${1} directory.
function analyze_group() {
	GROUP=$(basename "${1}")
	log_analysis_message "group '${GROUP}'"

	export OUT_DIR="${REPORTS_DIR}/${STEP}__TRIVY__${GROUP}"
	mkdir -p "${OUT_DIR}"

	analyze "${REPORTS_DIR}/list__${GROUP}__all_init_apps.txt"

	log_console_success "Open this directory for the results: ${OUT_DIR}"
}

function main() {

	if [[ "${DEBUG}" == "true" ]]; then
		set -x
		exec 6>&1
	else
		exec 6>/dev/null
	fi

	log_tool_info "Trivy v${VERSION}"

	if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_TRIVY}") ]]; then
		mkdir -p "${TRIVY_VULN_CACHE_DIR}"
		for_each_group analyze_group
	else
		log_console_error "Trivy analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_TRIVY}'"
	fi

}

main
