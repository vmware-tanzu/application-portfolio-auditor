#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Unzip all source files and copy all file directories to ${APP_GROUP_SRC_DIR}.
##############################################################################################################

STEP=$(get_step)
export LOG_FILE=${REPORTS_DIR}/${STEP}__unpack_sources.log

function unpack() {
	mkdir -p "${APP_GROUP_SRC_DIR}" "${REPORTS_DIR}"

	while read -r APP; do

		APP_NAME=$(basename "${APP}")
		APP_DIR="${APP_GROUP_SRC_DIR}/${APP_NAME%.*}"

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

	done < <(find "${APP_GROUP_DIR}" -maxdepth 1 -mindepth 1 -type f -name '*.zip')

	while read -r FOLDER; do
		cp -Rfp "${FOLDER}" "${APP_GROUP_SRC_DIR}/."
	done < <(find "${APP_GROUP_DIR}" -maxdepth 1 -mindepth 1 -type d ! -name 'src')
}

function main() {
	set +e
	check_debug_mode
	unpack
	set -e
}

main
