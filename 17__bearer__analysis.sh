#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all applications in ${APP_DIR_IN} grouped in sub-folders using ...
#   "Bearer" - https://github.com/bearer/bearer
#
# "Bearer" scans source code against top security and privacy risks.
##############################################################################################################

# ----- Please adjust
THREADS=10

# ------ Do not modify
VERSION=${BEARER_VERSION}
STEP=$(get_step)
CONTAINER_IMAGE_NAME_BEARER="bearer/bearer:v${VERSION}"

export LOG_FILE=${REPORTS_DIR}/${STEP}__BEARER.log

# Analyse all applications present in provided list.
function analyze() {

	local -r APP_LIST=${1}
	if [[ -s "${APP_LIST}" ]]; then
		while read -r APP; do
			local APP_NAME=$(basename "${APP}")
			local APP_FOLDER=$(dirname "${APP}")
			log_analysis_message "app '${APP_NAME}'"

			set +e
			local PREFIX=""
			if [[ -f "${APP}" ]]; then
				PREFIX="file"
			elif [[ -d "${APP}" ]]; then
				PREFIX="dir"
			fi

			local APP_NAME_SHORT="${APP_NAME}"
			if [[ "${APP_NAME}" == *\.zip ]]; then
				APP_NAME_SHORT="${APP_NAME%.*}"
			fi

			local RESULT_FILE_SECURITY_BEARER="${OUT_DIR_BEARER}/${APP_NAME_SHORT}_security_bearer.html"
			if [[ -z "${PREFIX}" ]]; then
				log_console_error "Invalid application: '${APP}'"
			else
				## Run -Bearer- to generate HTML security report
				${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm \
					-v "${APP_FOLDER}/src/${APP_NAME_SHORT}:/src/${APP_NAME_SHORT}" \
					-e SYFT_CHECK_FOR_APP_UPDATE=false \
					"${CONTAINER_IMAGE_NAME_BEARER}" \
					scan -f html --scanner=secrets,sast --hide-progress-bar --parallel=${THREADS} --report security "/src" 2>>"${LOG_FILE}" >"${RESULT_FILE_SECURITY_BEARER}"

				## Run -Bearer- to generate HTML privacy report
				#${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm \
				#	-v "${APP_FOLDER}:/src" \
				#	-e SYFT_CHECK_FOR_APP_UPDATE=false \
				#	"${CONTAINER_IMAGE_NAME_BEARER}" \
				#	scan -f html --hide-progress-bar --parallel=${THREADS} --report privacy "/src" 2>>"${LOG_FILE}" >"${RESULT_FILE_PRIVACY_BEARER}"
			fi
			set -e
		done <"${APP_LIST}"
	fi
}

# Analyse all applications present in the ${1} directory.
function analyze_group() {
	local -r GROUP=$(basename "${1}")
	log_analysis_message "group '${GROUP}'"
	analyze "${REPORTS_DIR}/list__${GROUP}__all_init_apps.txt"
	log_console_success "Open this directory for the results: ${OUT_DIR_BEARER}"
}

function main() {

	log_tool_info "Bearer v${VERSION}"

	if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_BEARER}") ]]; then
		export OUT_DIR_BEARER="${REPORTS_DIR}/${STEP}__BEARER"
		rm -Rf "${OUT_DIR_BEARER}"
		mkdir -p "${OUT_DIR_BEARER}"
		for_each_group analyze_group
	else
		log_console_error "Bearer analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_BEARER}'"
	fi

}

main
