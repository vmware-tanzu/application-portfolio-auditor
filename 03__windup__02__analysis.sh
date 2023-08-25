#!/usr/bin/env bash
# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all binary applications (EAR/WAR/JAR) in ${APP_DIR_IN} grouped in sub-folders using ...
#   "Windup" - https://github.com/windup/windup
##############################################################################################################

set -eu

# ----- Please adjust

# List of files containing a list of plain Java packages to INCLUDE
INCLUDE_FILES=("${WINDUP_INCLUDE_PACKAGES_FILE}" "${CURRENT_DIR}/conf/Windup/include.packages")
# List of files containing a list of plain Java packages to EXCLUDE
EXCLUDE_FILES=("${WINDUP_EXCLUDE_PACKAGES_FILE}" "${CURRENT_DIR}/conf/Windup/exclude.packages" "${CURRENT_DIR}/conf/Windup/exclude_JDK.packages")

## Windup analysis targets
TARGET="cloud-readiness openjdk resteasy eap6 eap7 linux jakarta-ee java-ee"

# ------ Do not modify
VERSION=${WINDUP_VERSION}
STEP=$(get_step)
CONTAINER_IMAGE_NAME_WINDUP="windup:${VERSION}"

INCLUDE_PACKAGES=()
EXCLUDE_PACKAGES=()

LOG_FILE="${REPORTS_DIR}/${STEP}__WINDUP.log"

# Analyse all applications present in the ${1} directory.
function analyze() {

	APP_DIR_INCOMING=${1}
	# Temporary folder for the analyzed applications
	APP_DIR_IN_TMP=${APP_DIR_INCOMING}/tmp
	GROUP=$(basename "${APP_DIR_INCOMING}")
	APP_DIR_OUT=${REPORTS_DIR}/${STEP}__WINDUP__${GROUP}
	log_analysis_message "group '${GROUP}'"

	rm -Rf "${APP_DIR_IN_TMP}"

	# -> Java binary apps
	LIST_JAVA_BIN=${REPORTS_DIR}/list__${GROUP}__java-bin.txt
	# -> Java apps initially provided as source code
	LIST_JAVA_SRC_INIT=${REPORTS_DIR}/list__${GROUP}__java-src-init.txt

	# Windup can deal with compiled and source apps at the same time.
	# Source code directories need to have a name ending by ".jar" ".war" or ".ear"
	if [[ -s "${LIST_JAVA_BIN}" || -s "${LIST_JAVA_SRC_INIT}" ]]; then

		mkdir -p "${APP_DIR_OUT}" "${APP_DIR_IN_TMP}"

		while read -r FILE; do
			cp -fp "${FILE}" "${APP_DIR_IN_TMP}/." || true
		done <"${LIST_JAVA_BIN}"

		# Needed to make sure that the source code directories are visible for Windup
		while read -r DIR; do
			BASENAME=$(basename "${DIR}")
			cp -Rfp "${DIR}" "${APP_DIR_IN_TMP}/." || true
			mv "${APP_DIR_IN_TMP}/${BASENAME}" "${APP_DIR_IN_TMP}/${BASENAME}_SRC.jar"
		done <"${LIST_JAVA_SRC_INIT}"

		local ARGS=(
			-b
			--target "${TARGET}"
			--input "/${GROUP}"
			--output "/cache"
			--overwrite
		)

		if [[ "${HAS_INTERNET_CONNECTION}" == "false" ]]; then
			log_console_info "No internet connectivity. Configuring Windup for offline usage."
		else
			ARGS+=(--online)
		fi

		[[ -n "${INCLUDE_PACKAGES[*]:-}" ]] && ARGS+=(--packages "${INCLUDE_PACKAGES[*]}")
		[[ -n "${EXCLUDE_PACKAGES[*]:-}" ]] && ARGS+=(--excludePackages "${EXCLUDE_PACKAGES[*]}")
		ARGS+=(
			--enableTransactionAnalysis
			--exportCSV
			-d
		)

		log_console_info "INCLUDE: ${INCLUDE_PACKAGES[*]:-none}"
		log_console_info "EXCLUDE: ${EXCLUDE_PACKAGES[*]:-none}"

		set +e
		(time ${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm -v "${APP_DIR_IN_TMP}:/${GROUP}:ro" -v "${APP_DIR_OUT}:/out:delegated" -v "tmpfs:/cache:delegated" --name Windup "${CONTAINER_IMAGE_NAME_WINDUP}" "${ARGS[@]}") >>"${LOG_FILE}" 2>&1

		# Hack to fix the issue with files created with root user
		if sudo -n ls >/dev/null 2>&1; then
			sudo chown -R "$(id -u):$(id -g)" "${APP_DIR_OUT}"
		fi
		set -e

		# Cleanup
		rm -Rf "${APP_DIR_IN_TMP}"

		if [[ -s "${APP_DIR_OUT}/index.html" ]]; then
			log_console_success "Results: ${APP_DIR_OUT}/index.html"
		else
			log_console_warning "Unknown issue. No report has been generated."
		fi
	else
		log_console_warning "No Java application found. Skipping Windup analysis."
	fi
}

function load_packages() {
	OP=${1}
	IS_FIRST=true
	while IFS='' read -r LINE; do
		[[ "${OP}" == "EXCLUDE" ]] && EXCLUDE_PACKAGES+=("${LINE}") && continue
		[[ "${OP}" == "INCLUDE" ]] && INCLUDE_PACKAGES+=("${LINE}")
	done < <(
		{
			for FILE in "${@}"; do
				[[ ${IS_FIRST} == true ]] && IS_FIRST=false && continue
				[[ -f "${FILE}" ]] && cat "${FILE}"
			done
		} | grep -Eo '^[^#]+' | sort | uniq
	)
}

function main() {

	log_tool_info "Windup v${VERSION}"
	if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_WINDUP}") ]]; then

		# Load exclude packages from files
		load_packages EXCLUDE "${EXCLUDE_FILES[@]}"

		# Load include packages from files
		load_packages INCLUDE "${INCLUDE_FILES[@]}"

		# Run Windup
		for_each_group analyze

	else
		log_console_error "Windup analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_WINDUP}'"
	fi
}

main
