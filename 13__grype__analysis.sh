#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all applications in ${APP_DIR_IN} grouped in sub-folders using ...
#   "Grype" & "Syft" - https://anchore.com/opensource/
#
# "Grype" & "Syft" are developer-friendly scanning tools for application security.
##############################################################################################################

# ----- Please adjust

# ------ Do not modify
VERSION=${GRYPE_VERSION}
STEP=$(get_step)
GRYPE_VULN_CACHE_DIR="${DIST_DIR}/grype_cache"
export OUT_DIR="${REPORTS_DIR}/${STEP}__GRYPE"
export LOG_FILE="${OUT_DIR}.log"

# Analyze all applications present in provided list.
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
				PREFIX="file"
			elif [[ -d "${APP}" ]]; then
				PREFIX="dir"
			fi

			APP_NAME_SHORT="${APP_NAME}"
			if [[ "${APP_NAME}" == *\.zip ]]; then
				APP_NAME_SHORT="${APP_NAME%.*}"
			fi
			GRYPE_OUTPUT="${OUT_DIR}/${APP_NAME_SHORT}_grype.csv"

			if [[ -z "${PREFIX}" ]]; then
				log_console_error "Invalid application: '${APP}'"
			else
				## Run -Syft- to generate SBOM
				${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} \
					-v "${APP_FOLDER}:/src" -v "${OUT_DIR}:/out" \
					-e SYFT_CHECK_FOR_APP_UPDATE=false \
					"${CONTAINER_IMAGE_NAME_SYFT}" \
					"${PREFIX}:/src/${APP_NAME}" -o "json=/out/${APP_NAME_SHORT}_syft.json" 2>>"${LOG_FILE}"
			fi

			# Check if SBOM is not empty
			if [[ -f "${OUT_DIR}/${APP_NAME_SHORT}_syft.json" ]] && [[ -s "${OUT_DIR}/${APP_NAME_SHORT}_syft.json" ]]; then
				## Run -Grype- using the -Syft- output file and using a locally cached DB
				#set -x
				${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm \
					-v "${GRYPE_VULN_CACHE_DIR}:/db" -v "${DIST_DIR}/templating:/tmpl:ro" -v "${OUT_DIR}:/out:delegated" \
					-e GRYPE_CHECK_FOR_APP_UPDATE=false -e GRYPE_DB_CACHE_DIR="/db" -e GRYPE_DB_VALIDATE_AGE="${HAS_INTERNET_CONNECTION}" -e GRYPE_DB_AUTO_UPDATE="${HAS_INTERNET_CONNECTION}" \
					--name Grype "${CONTAINER_IMAGE_NAME_GRYPE}" \
					-q -o template -t "/tmpl/grype_csv.tmpl" "/out/${APP_NAME_SHORT}_syft.json" >"${GRYPE_OUTPUT}.tmp" 2>>"${LOG_FILE}"

				#set +x
				## Replace quote by simple ones to avoid later HTML rendering issues ("description" field)
				sed 's/"/\x27\x27/g; s/`/\x27/g; s/____/"/g' "${GRYPE_OUTPUT}.tmp" >"${GRYPE_OUTPUT}"
				rm -f "${GRYPE_OUTPUT}.tmp"
			fi

			set -e
		done <"${APP_LIST}"
	fi
}

function main() {
	log_tool_info "Syft v${SYFT_VERSION}"
	log_tool_info "Grype v${VERSION}"

	if [[ "${HAS_INTERNET_CONNECTION}" == "false" ]]; then
		log_console_info "No internet connectivity. Configuring Grype for offline usage."
	fi

	if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_SYFT}") ]]; then
		if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_GRYPE}") ]]; then
			# Analyze all applications present in the ${APP_GROUP_DIR} directory.
			check_debug_mode
			mkdir -p "${GRYPE_VULN_CACHE_DIR}" "${OUT_DIR}"
			analyze "${REPORTS_DIR}/list__${APP_GROUP}__all_init_apps.txt"
			log_console_success "Open this directory for the results: ${OUT_DIR}"
		else
			log_console_error "Grype analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_GRYPE}'"
		fi
	else
		log_console_error "Grype analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_SYFT}'"
	fi
}

main
