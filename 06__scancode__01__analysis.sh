#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all binary applications (EAR/WAR/JAR) in ${APP_DIR_IN} grouped in sub-folders using ...
#   "ScanCode toolkit" - https://github.com/nexB/scancode-toolkit
#
# "ScanCode toolkit" detects licenses, copyrights, package manifests & dependencies and more
#    by scanning code to discover and inventory open source and third-party packages in use.
##############################################################################################################

# ----- Please adjust
THREADS=10
TIMEOUT=90

# ------ Do not modify
VERSION=${SCANCODE_VERSION}
STEP=$(get_step)
APP_DIR_OUT=${REPORTS_DIR}/${STEP}__SCANCODE
export LOG_FILE=${APP_DIR_OUT}.log

# Unpack and delete an archive
function unpack() {
	set +e
	FILE="${1}"
	log_console_info "Unpacking '${FILE}'"
	OUTPUT_DIR="${1%.*}_${1##*.}"
	[[ -d "${OUTPUT_DIR}" ]] && rm -Rf "${OUTPUT_DIR}"
	mkdir -p "${OUTPUT_DIR}"
	UNZIP_OPTS=(-o -P pass "${FILE}" -d "${OUTPUT_DIR}")
	# shellcheck disable=SC2143
	if [[ -n "$(unzip -l "${FILE}" | grep -E ' /$')" ]]; then
		UNZIP_OPTS+=(-x)
		UNZIP_OPTS+=(-/)
	fi
	unzip "${UNZIP_OPTS[@]}" >&6 2>&1
	RC=$?
	if [[ ${RC} -ne 0 ]]; then
		log_console_error "Error while extracting '${FILE}' (${RC})"
		# Remove temporary directory.
		rm -Rf "${OUTPUT_DIR}"
		# Rename the file reflecting the encountered error.
		mv "${FILE}" "${FILE}.${RC}.corrupted"
	fi
	rm -f "${FILE}"
	set -e
}

# Remove dependency to result folder
function cleanup_html() {
	TARGET_FILE=${1}
	DIR_OUT=${2}
	if [ -f "${OUTPUT_REPORT}" ] && [ -f "${TARGET_FILE}" ]; then
		stream_edit "s|${DIR_OUT}/|./|g" "${TARGET_FILE}"
		# Cleaning up 'help.html'
		stream_edit "s|js/jquery.js|jquery.min.js|g" "${TARGET_FILE}"
		stream_edit "s|js/bootstrap.min.js|bootstrap.min.js|g" "${TARGET_FILE}"
		stream_edit 's|class="btn btn-default" id="menu-toggle"|class="btn btn-default"|g' "${TARGET_FILE}"
	fi
}

# Analyze all applications present in the ${APP_GROUP_DIR} directory.
function analyze() {
	rm -Rf "${APP_GROUP_TMP_DIR}" "${APP_DIR_OUT}"
	mkdir -p "${APP_DIR_OUT}" "${APP_GROUP_TMP_DIR}"
	cp -Rfp "${APP_GROUP_SRC_DIR}" "${APP_GROUP_TMP_DIR}"

	while read -r IGNORED_ARCHIVE; do
		NEW_ARCHIVE="${IGNORED_ARCHIVE%.*}"
		mv "${IGNORED_ARCHIVE}" "${NEW_ARCHIVE}"
		unpack "${NEW_ARCHIVE}"
	done < <(find "${APP_GROUP_TMP_DIR}" -type f -iname '*.ignored_*')

	# Make non-readable files readable.
	find "${APP_GROUP_TMP_DIR}" ! -perm -o=r -exec chmod +r {} +

	# Remove remaining compiled classes to accelerate the analysis
	find "${APP_GROUP_TMP_DIR}" -type f -iname '*.class' -delete
	find "${APP_GROUP_TMP_DIR}" -type f -iname '*.so' -delete

	# Remove cache files to accelerate the analysis
	find "${APP_GROUP_TMP_DIR}" -type f -regex '^.*/[A-Za-z0-9.]\{32\}\.cache.html$' -delete
	find "${APP_GROUP_TMP_DIR}" -type f -regex '^.*/gwt-unitCache-[A-Za-z0-9.]\{40\}-[A-Za-z0-9.]\{16\}$' -delete
	find "${APP_GROUP_TMP_DIR}" -type f -regex '^.*/[A-Za-z0-9.]\{32\}\.symbolMap$' -delete

	while read -r APP_DIR_TMP; do
		APP_NAME=$(basename "${APP_DIR_TMP}")
		log_console_info "Launching ScanCode for app '${APP_NAME}'"

		mkdir -p "${APP_DIR_OUT}/${APP_NAME}"

		set +e
		${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} -v "${APP_DIR_TMP}:/app/${APP_NAME}:ro" -v "tmpfs:/cache:delegated" -v "${APP_DIR_OUT}:/out:delegated" "${CONTAINER_IMAGE_NAME_SCANCODE}" \
			--license --license-references --license-text --license-score 0 --classify --license-clarity-score \
			--url --info --email \
			--package \
			--copyright \
			--html-app "/out/${APP_NAME}/index.html" "/cache/${APP_NAME}" --verbose -n "${THREADS}" --timeout "${TIMEOUT}" \
			--ignore "*.gif" --ignore "*.pdf" --ignore "*.rtf" --ignore "*.idx" --ignore "*.csv" --ignore "/test" --ignore "/tests" --ignore "*.jmx" --ignore "*.sha1" --ignore "*.git" --ignore "*.mvn" >>"${LOG_FILE}" 2>&1

		# Hack to fix the issue with files created with root user
		if sudo -n ls >/dev/null 2>&1; then
			sudo chown -R "$(id -u):$(id -g)" "${APP_DIR_OUT}"
		fi
		set -e

		OUTPUT_DIR="${APP_DIR_OUT}/${APP_NAME}"
		OUTPUT_REPORT="${OUTPUT_DIR}/index.html"
		OUTPUT_HELP_FILE="${OUTPUT_DIR}/index_files/help.html"

		if [[ -f "${OUTPUT_REPORT}" ]]; then
			# Removing dependency to result folder
			cleanup_html "${OUTPUT_REPORT}" "/out/${APP_NAME}"
			cleanup_html "${OUTPUT_HELP_FILE}" "/out/${APP_NAME}"
			stream_edit 's|/cache/||g' "${OUTPUT_REPORT}"
			log_console_success "Open this directory for the results: ${OUTPUT_REPORT}"
		else
			log_console_error "No report generated. See '${LOG_FILE}' for more details."
		fi

	done < <(find "${APP_GROUP_TMP_DIR}/src" -maxdepth 1 -mindepth 1 -type d | sort)

	# Cleanup
	rm -Rf "${APP_GROUP_TMP_DIR}"
}

function main() {
	log_tool_info "ScanCode v${VERSION}"
	if [[ -n "$(${CONTAINER_ENGINE} images -q ${CONTAINER_IMAGE_NAME_SCANCODE})" ]]; then
		check_debug_mode
		analyze
	else
		log_console_error "ScanCode analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_SCANCODE}'"
	fi
}

main
