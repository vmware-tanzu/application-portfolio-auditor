#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all applications in ${APP_DIR_IN} grouped in sub-folders using ...
#   "SLSCAN" - https://github.com/ShiftLeftSecurity/sast-scan & https://slscan.io/en/latest/
#
# "SLSCAN" is a free & Open Source DevSecOps tool for performing static analysis based security testing of your applications and its dependencies.
##############################################################################################################

# ----- Please adjust
# Will conduct an in-depth OSS audit the application dependencies. Requires Internet access.
ENABLE_OSS_RISK=false
# More verbose log output
SCAN_DEBUG_MODE=debug
SCAN_AUTO_BUILD=false

# ------ Do not modify
VERSION=${SLSCAN_VERSION}
STEP=$(get_step)

export APP_NAME LOG_FILE APP_DIR_OUT
APP_DIR_OUT="${REPORTS_DIR}/${STEP}__SLSCAN"
LOG_FILE="${APP_DIR_OUT}.log"

ANALYZABLE_APP_FOUND="false"

# Analyze all applications present in provided list.
function analyze() {

	LANGUAGE=${1}
	APP_LIST=${2}

	if [[ -s "${APP_LIST}" ]]; then
		while read -r APP; do
			APP_NAME=$(basename "${APP}")
			log_analysis_message "app (${LANGUAGE}) '${APP_NAME}'"

			EXECUTION_LOG_FILE="${APP_DIR_OUT}/${APP_NAME}.log"
			SUMMARY_FILE_TXT="${APP_DIR_OUT}/${APP_NAME}.txt"

			set +e
			# Run SLSCAN
			${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm -e ENABLE_OSS_RISK="${ENABLE_OSS_RISK}" -e SCAN_AUTO_BUILD="${SCAN_AUTO_BUILD}" -e SCAN_DEBUG_MODE="${SCAN_DEBUG_MODE}" -e "WORKSPACE=${APP}" -v "${APP}:/app" "${CONTAINER_IMAGE_NAME_SLSCAN}" scan --build --local-only >"${EXECUTION_LOG_FILE}" 2>&1

			sed -n '/.*Tool.*Critical.*$/,$p' "${EXECUTION_LOG_FILE}" | sed '$d' >"${SUMMARY_FILE_TXT}"

			SLSCAN_REPORTS_DIR="${APP}/reports"
			if [[ -d "${SLSCAN_REPORTS_DIR}" ]]; then
				if sudo -n ls >/dev/null 2>&1; then
					sudo chown -R "$(id -u):$(id -g)" "${SLSCAN_REPORTS_DIR}"
				fi
				ANALYZABLE_APP_FOUND="true"
				cp -Rfp "${SLSCAN_REPORTS_DIR}" "${APP_DIR_OUT}/${APP_NAME}"
				rm -Rf "${SLSCAN_REPORTS_DIR}"
			fi
			set -e
		done <"${APP_LIST}"
	fi
}

function main() {
	log_tool_info "SLSCAN v${VERSION}"

	if [[ "${ARCH}" == "arm64" ]]; then
		log_console_error "SLSCAN is not supported on ARM64. It will be skipped."
		exit
	fi

	if [[ "${HAS_INTERNET_CONNECTION}" == "false" ]]; then
		log_console_info "No internet connectivity. Overriding ENABLE_OSS_RISK setting."
		ENABLE_OSS_RISK="false"
	fi

	if [[ -n "$(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_SLSCAN}")" ]]; then
		check_debug_mode

		mkdir -p "${APP_DIR_OUT}"

		analyze java "${REPORTS_DIR}/list__${APP_GROUP}__java-src.txt"
		analyze python "${REPORTS_DIR}/list__${APP_GROUP}__python.txt"
		analyze javascript "${REPORTS_DIR}/list__${APP_GROUP}__js.txt"
		analyze cs "${REPORTS_DIR}/list__${APP_GROUP}__cs.txt"

		if [[ "${ANALYZABLE_APP_FOUND}" == "true" ]]; then
			log_console_success "Open this directory for the results: ${APP_DIR_OUT}"
		else
			log_console_warning "No suitable app found. Skipping SLSCAN analysis."
		fi
	else
		log_console_error "SLSCAN analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_SLSCAN}'"
	fi
}

main
