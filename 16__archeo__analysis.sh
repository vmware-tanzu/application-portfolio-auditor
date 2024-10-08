#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all applications in ${APP_DIR_IN} grouped in sub-folders using "Archeo".
#
# "Archeo" detects technical debt in your application. It has been developed within "Application Portfolio Auditor.
##############################################################################################################

# ----- Please adjust

# ------ Do not modify
VERSION=${TOOL_VERSION}
STEP=$(get_step)

export OUT_DIR_ARCHEO="${REPORTS_DIR}/${STEP}__ARCHEO"
export LOG_FILE="${OUT_DIR_ARCHEO}.log"
APP_LIST="${REPORTS_DIR}/00__Weave/list__all_init_apps.txt"

# ------ Analyze all applications present in ${1}
function analyze_application() {
	local APP APP_NAME APP_FOLDER PREFIX APP_NAME_SHORT RESULT_JSON RESULT_FILE_SYFT RESULT_FILE_ARCHEO

	APP="${1}"
	APP_NAME=$(basename "${APP}")
	APP_FOLDER=$(dirname "${APP}")
	log_analysis_message "app '${APP_NAME}'"

	set +e

	PREFIX=""
	if [[ -f "${APP}" ]]; then
		PREFIX="file"
	elif [[ -d "${APP}" ]]; then
		PREFIX="dir"
	fi

	APP_NAME_SHORT="${APP_NAME}"
	if [[ "${APP_NAME}" == *\.zip ]]; then
		APP_NAME_SHORT="${APP_NAME%.*}"
	fi

	RESULT_JSON="${APP_NAME_SHORT}_syft_spdx.json"
	if [[ -z "${PREFIX}" ]]; then
		log_console_error "Invalid application: '${APP}'"
	else
		## Run -Syft- to generate SBOM
		${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} \
			-v "${APP_FOLDER}:/src" -v "${OUT_DIR_ARCHEO}:/out" \
			-e SYFT_CHECK_FOR_APP_UPDATE=false \
			"${CONTAINER_IMAGE_NAME_SYFT}" \
			"${PREFIX}:/src/${APP_NAME}" -o "spdx-json=/out/${RESULT_JSON}" 2>>"${LOG_FILE}"
	fi

	RESULT_FILE_SYFT="${OUT_DIR_ARCHEO}/${RESULT_JSON}"
	RESULT_FILE_ARCHEO="${OUT_DIR_ARCHEO}/${APP_NAME_SHORT}_archeo.txt"
	# Check if SBOM is not empty
	if [[ -f "${RESULT_FILE_SYFT}" ]] && [[ -s "${RESULT_FILE_SYFT}" ]]; then
		# Filter Syft results to generate a list of all packages found
		jq -r ' .packages[] | select(.externalRefs) .externalRefs[] | select(.referenceCategory == "PACKAGE-MANAGER") | .referenceLocator' "${RESULT_FILE_SYFT}" | sort | uniq >>"${RESULT_FILE_ARCHEO}"
	fi
	set -e
}

# ------
function main() {
	log_tool_info "Syft v${SYFT_VERSION}"
	log_tool_info "Archeo v${VERSION}"
	if [[ -s "${APP_LIST}" ]]; then
		if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_SYFT}") ]]; then
			check_debug_mode
			mkdir -p "${OUT_DIR_ARCHEO}"
			# Analyze all applications listed in ${APP_LIST}.
			while read -r APP; do
				analyze_application "${APP}"
			done <"${APP_LIST}"
			log_console_success "Open this directory for the results: ${OUT_DIR_ARCHEO}"
		else
			log_console_error "Archeo analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_SYFT}'"
		fi
	else
		log_console_error "Archeo analysis canceled. Empty application list: '${APP_LIST}'"
	fi
}

main
