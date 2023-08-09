#!/usr/bin/env bash
# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Unzip all source files and copy all file directories to ${APP_DIR_SRC}.
##############################################################################################################

STEP=$(get_step)
export LOG_FILE=${REPORTS_DIR}/${STEP}__unpack_sources.log

function unpack() {
	APP_DIR_INCOMING="${1}"
	APP_DIR_SRC="${APP_DIR_INCOMING}/src"
	GROUP=$(basename "${APP_DIR_INCOMING}")
	log_analysis_message "group '${GROUP}'"

	mkdir -p "${APP_DIR_SRC}" "${REPORTS_DIR}"

	while read -r APP; do

		APP_NAME=$(basename "${APP}")
		APP_DIR="${APP_DIR_SRC}/${APP_NAME%.*}"

		log_console_step "Extracting '${APP_NAME}' to ${APP_DIR} ..."

		rm -Rf "${APP_DIR}"
		mkdir -p "${APP_DIR}"
		unzip -d "${APP_DIR}" "${APP}" >/dev/null 2>&1

		# Remove first zip embedded subdir if present (e.g. GitHub source code download)
		SUBDIR_NAME=$(unzip -Z1 "${APP}" | head -n 1 | cut -d'/' -f1)
		if [[ -n "${SUBDIR_NAME}" ]]; then
			COUNT_FILES_ZIPPED=$(unzip -Z1 "${APP}" | wc -l)
			COUNT_FILES_SUBDIR_ZIPPED=$(unzip -Z1 "${APP}" | grep -c "${SUBDIR_NAME}")
			if ((COUNT_FILES_ZIPPED == COUNT_FILES_SUBDIR_ZIPPED)); then
				mv "${APP_DIR}/${SUBDIR_NAME}" "${APP_DIR}_${SUBDIR_NAME}"
				rm -Rf "${APP_DIR}"
				mv "${APP_DIR}_${SUBDIR_NAME}" "${APP_DIR}"
			fi
		fi

	done < <(find "${APP_DIR_INCOMING}" -maxdepth 1 -mindepth 1 -type f -name '*.zip')

	while read -r FOLDER; do
		cp -Rfp "${FOLDER}" "${APP_DIR_SRC}/."
	done < <(find "${APP_DIR_INCOMING}" -maxdepth 1 -mindepth 1 -type d ! -name 'src')
}

function main() {

	set +e
	if [[ "${DEBUG}" == "true" ]]; then
		set -x
		exec 6>&1
	else
		exec 6>/dev/null
	fi
	for_each_group unpack
	set -e
}

main
