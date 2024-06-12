#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all binary applications (EAR/WAR/JAR) in ${APP_DIR_IN} grouped in sub-folders using ...
#   "Open Web Application Security Project (OWASP) Dependency-Check" - https://www.owasp.org/index.php/OWASP_Dependency_Check
##############################################################################################################

# ----- Please adjust
#set -x

# Sets whether the Central Analyzer will be used. Disabling this analyzer is not recommended as it could lead to false negatives (e.g. libraries that have vulnerabilities may not be reported correctly).
DISABLE_CENTRAL_REPO="true"

# Sets whether to use the experimental Python scanner.
ENABLE_PYTHON_SCANNING="false"

# Generate verbose log for each application
ENABLE_VERBOSE_LOG="false"

# ------ Do not modify
VERSION=${OWASP_DC_VERSION}

STEP=$(get_step)
APP_DIR_OUT="${REPORTS_DIR}/${STEP}__OWASP_DC"
LOG_FILE="${APP_DIR_OUT}.log"

DATA_DIR="${DIST_DIR}/owasp_data"
CACHE_DIR="${DATA_DIR}/cache"

# Analyze all applications present in the ${APP_GROUP_DIR} directory.
function analyze() {

	mkdir -p "${APP_DIR_OUT}"

	while read -r APP; do
		APP_NAME=$(basename "${APP}")
		APP_DIR=$(dirname "${APP}")

		# OWASP analysis arguments
		ARGS=(
			--project "[${APP_GROUP}] ${APP_NAME}"
			-f ALL
			--out /report
			--scan "/apps/${APP_NAME}"
		)
		[[ "${ENABLE_VERBOSE_LOG}" == "true" ]] && ARGS+=(-l "${APP_DIR_OUT}__${APP_NAME}.log")
		# Append arguments valid for all scans
		ARGS+=("${ARGS_GLOBAL[@]}")

		set -x
		set +e
		(
			time ${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm \
				-e user=$USER \
				-u $(id -u ${USER}):$(id -g ${USER}) \
				--volume "${APP_DIR}":"/apps":ro \
				--volume "${DATA_DIR}":/usr/share/dependency-check/data:delegated \
				--volume "${APP_DIR_OUT}":/report:delegated \
				"${CONTAINER_IMAGE_NAME_OWASP_DC}" \
				"${ARGS[@]}"
		) >>"${LOG_FILE}" 2>&1
		set -e
		set +x

		if [[ -f "${APP_DIR_OUT}/dependency-check-junit.xml" ]]; then
			mv "${APP_DIR_OUT}/dependency-check-junit.xml" "${APP_DIR_OUT}/${APP_NAME}_dc_junit.xml"
			mv "${APP_DIR_OUT}/dependency-check-report.csv" "${APP_DIR_OUT}/${APP_NAME}_dc_report.csv"
			mv "${APP_DIR_OUT}/dependency-check-report.html" "${APP_DIR_OUT}/${APP_NAME}_dc_report.html"
			mv "${APP_DIR_OUT}/dependency-check-report.json" "${APP_DIR_OUT}/${APP_NAME}_dc_report.json"
			mv "${APP_DIR_OUT}/dependency-check-report.xml" "${APP_DIR_OUT}/${APP_NAME}_dc_report.xml"
		fi

		log_console_info "Results: ${APP_DIR_OUT}/${APP_NAME}_dc_report.html"

	done <"${REPORTS_DIR}/00__Weave/list__owasp_dc.txt"

	# Removes useless generated artifacts
	rm -f "${APP_DIR_OUT}/dependency-check-jenkins*"

	log_console_success "Open this directory for all results: ${APP_DIR_OUT}"
}

function main() {
	log_tool_info "OWASP DC (Open Web Application Security Project Dependency-Check) v${VERSION}"

	# Creating cache directory for vulnerability database
	if [ ! -d "${CACHE_DIR}" ]; then
		echo "Initially creating persistent directory: ${CACHE_DIR}"
		mkdir -p "${CACHE_DIR}"
	fi

	# Preparing arguments valid for all runs of OWASP dependency check
	export ARGS_GLOBAL=(
		--disableBundleAudit
		--disableRubygems
		--disableCocoapodsAnalyzer
	)
	[[ "${DISABLE_CENTRAL_REPO}" == "true" ]] && ARGS_GLOBAL+=(--disableCentral)
	[[ "${ENABLE_PYTHON_SCANNING}" == "true" ]] && {
		ARGS_GLOBAL+=(--enableExperimental)
		ARGS_GLOBAL+=(--disablePyDist "false")
		ARGS_GLOBAL+=(--disablePyPkg "false")
	}
	if [[ -n "${OWASP_DC_NVD_API_KEY}" ]]; then
		ARGS_GLOBAL+=(--nvdApiKey "${OWASP_DC_NVD_API_KEY}")
	elif [[ "${HAS_INTERNET_CONNECTION}" == "true" ]]; then
		log_console_warning "Disabling updates of the vulnerability DB. Request an NVD API key on https://nvd.nist.gov/developers/request-an-api-key and set it in '_shared_functions.sh' for updates."
		ARGS_GLOBAL+=(--noupdate)
	fi
	[[ "${HAS_INTERNET_CONNECTION}" == "false" ]] && ARGS_GLOBAL+=(--noupdate --disableOssIndex)

	# Analyze the applications
	analyze
}

main
