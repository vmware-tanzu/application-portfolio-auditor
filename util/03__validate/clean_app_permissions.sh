#!/usr/bin/env bash
# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Clean bad permissions on files within the analyzed applications.
#
# This script recursively extract Java binaries and updates all files permissions.
##############################################################################################################

DEFAULT_PERMISSION="777"

# ------ Do not modify
APP_DIR="${1}"
APP_DIR_BACKUP="${APP_DIR}_bckp"
TMP_DIR="${APP_DIR}_tmp"

# Script usage instructions
function usage() {
	printf "usage: ${B}%-8s${N} <folder_with_apps>\n" "$(basename "$0")"
	exit 2
}

# Unpack and delete an archive
function unpack() {
	FILE="${1}"
	echo "Unpacking '${FILE}'"
	OUTPUT_DIR="${1%.*}_${1##*.}"
	[[ -d "${OUTPUT_DIR}" ]] && sudo rm -Rf "${OUTPUT_DIR}"
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
		echo "Error while extracting '${FILE}' (${RC})"
		# Remove temporary directory.
		sudo clearrm -Rf "${OUTPUT_DIR}"
		# Rename the file reflecting the encountered error.
		sudo mv "${FILE}" "${FILE}.${RC}.corrupted"
	fi
	sudo rm -f "${FILE}"
	sudo chmod -R "${DEFAULT_PERMISSION}" "${OUTPUT_DIR}"
}

# Repackage one exploded archive
function repack() {
	local ARCHIVE_DIR="${1}"
	local EXT="${2}"
	local REGEX='s/\(.*\)_'"${EXT}"'$/\1.'"${EXT}"'/'
	local ARCHIVE=$(echo "${ARCHIVE_DIR}" | sed -e "${REGEX}")

	echo "Repacking '${ARCHIVE_DIR}' to '${ARCHIVE}'"
	# Zip public directory
	pushd "${ARCHIVE_DIR}" &>/dev/null
	set +e
	zip -r "${ARCHIVE}" . &>/dev/null
	rm -Rf "${ARCHIVE_DIR}"
	set -e
	popd &>/dev/null
}

# Repackage all exploded archives
function repack_all() {
	# Repackage all JARs
	while read -r JAR_ARCHIVE_DIR; do
		repack "${JAR_ARCHIVE_DIR}" "jar"
	done < <(find "${TMP_DIR}" -type d -iname '*_jar')

	# Repackage all WARs
	while read -r WAR_ARCHIVE_DIR; do
		repack "${WAR_ARCHIVE_DIR}" "war"
	done < <(find "${TMP_DIR}" -type d -iname '*_war')

	# Repackage all EARs
	while read -r EAR_ARCHIVE_DIR; do
		repack "${EAR_ARCHIVE_DIR}" "ear"
	done < <(find "${TMP_DIR}" -type d -iname '*_ear')
}

# Repack applications to a single huge application without sub-WAR/JAR file
function unpack_and_decompile() {

	while [ "$(find "${TMP_DIR}" -type f -iname '*.war' \
		-o -type f -iname '*.ear' \
		-o -type f -iname '*.jar' | wc -l | tr -d ' ')" -gt 0 ]; do

		while read -r ARCHIVE; do
			PARENT_DIR_NAME=$(basename "$(dirname "${ARCHIVE}")")
			TMP_DIR_NAME=$(basename "${TMP_DIR}")
			ARCHIVE_SHORT_NAME="${ARCHIVE:${#TMP_DIR}+1}"
			SHA1_LONG=$(sha1sum "${ARCHIVE}")
			SHA1=$(echo "${SHA1_LONG}" | cut -d' ' -f 1)

			if [[ "${TMP_DIR_NAME}" == "${PARENT_DIR_NAME}" ]]; then
				# Unpack every app present in the parent directory in all cases
				unpack "${ARCHIVE}"
				echo "${SHA1} [UNPACKED APP    ] ${ARCHIVE_SHORT_NAME}"
			else
				echo "${SHA1}  ${ARCHIVE_SHORT_NAME}"
				echo "${SHA1} [UNPACKED LIB    ] ${ARCHIVE_SHORT_NAME}"
				unpack "${ARCHIVE}"
			fi
		done < <(find "${TMP_DIR}" -type f -iname '*.war' \
			-o -type f -iname '*.ear' \
			-o -type f -iname '*.jar')

	done

}

function main() {

	if [[ "${DEBUG}" == "true" ]]; then
		set -x
		exec 6>&1
	else
		exec 6>/dev/null
	fi

	# Validate repository
	if [ ! -d "${APP_DIR}" ]; then
		usage
	fi

	if [[ -n $(find "${APP_DIR}" -mindepth 1 -maxdepth 1 -type f -iname '*.war' -o -type f -iname '*.ear' -o -type f -iname '*.jar') ]]; then

		# Cleanup temporary directory
		sudo rm -Rf "${TMP_DIR}"
		cp -Rfp "${APP_DIR}" "${TMP_DIR}"

		# Create backup directory if not already existing
		if [ ! -d "${APP_DIR_BACKUP}" ]; then
			cp -Rfp "${APP_DIR}" "${APP_DIR_BACKUP}"
		fi

		set +e
		# Recursively unpack all archives and fix permissions
		unpack_and_decompile

		# Recursively repack all archives
		repack_all

		# Replace original directory with the temporary one
		sudo rm -Rf "${APP_DIR}"
		mv "${TMP_DIR}" "${APP_DIR}"
		set -e
	else
		echo "Error: No valid application found in '${APP_DIR}'"
		usage
	fi

}

main
