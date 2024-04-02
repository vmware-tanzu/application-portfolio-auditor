#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Enumerate all Java packages used by the apps in ${APP_DIR_IN} and output them in in ${PACKAGE_DIR_OUT} using ...
#   "Windup" - https://github.com/windup/windup
##############################################################################################################

set -eu

# ------ Do not modify
VERSION=${WINDUP_VERSION}
STEP=$(get_step)

PACKAGE_DIR_OUT=${REPORTS_DIR}/${STEP}__WINDUP__packages
export LOG_FILE=${PACKAGE_DIR_OUT}.log

ALL_PACKAGES_SHORT="_all.packages"
ALL_PACKAGES="${PACKAGE_DIR_OUT}/${ALL_PACKAGES_SHORT}"
ALL_UNKNOWN_PACKAGES_SHORT="_all_unknown.packages"
ALL_UNKNOWN_PACKAGES="${PACKAGE_DIR_OUT}/${ALL_UNKNOWN_PACKAGES_SHORT}"
ALL_KNOWN_PACKAGES_SHORT="_all_known.packages"
ALL_KNOWN_PACKAGES="${PACKAGE_DIR_OUT}/${ALL_KNOWN_PACKAGES_SHORT}"
TOKEN="XXXXXXXXXXX"
JAVA_BIN_APP_FOUND="false"
PACKAGE_FILE="${PACKAGE_DIR_OUT}/${APP_GROUP}.txt"
JAVA_BIN_LIST="${REPORTS_DIR}/list__${APP_GROUP}__java-bin.txt"

# Analyze all applications present in the ${APP_GROUP_DIR} directory.
function analyze_packages() {
	if [[ -s "${JAVA_BIN_LIST}" ]]; then
		JAVA_BIN_APP_FOUND="true"
		mkdir -p "${APP_GROUP_TMP_DIR}"
		while read -r FILE; do
			cp -fp "${FILE}" "${APP_GROUP_TMP_DIR}/." || true
		done <"${JAVA_BIN_LIST}"

		set +e
		(time ${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm -v "${APP_GROUP_TMP_DIR}:/apps" --name Windup "${CONTAINER_IMAGE_NAME_WINDUP}" -b --discoverPackages --input "/apps" -d >"${PACKAGE_FILE}") >>"${LOG_FILE}" 2>&1

		stream_edit '1,/Known Packages:/d' "${PACKAGE_FILE}"

		echo "Known Packages:" >/tmp/pack
		cat "${PACKAGE_FILE}" >>/tmp/pack
		# Fix for too many "Weld" entries
		grep -v "org.jboss.weld.environment.se.WeldContainer" /tmp/pack | grep -v "Weld SE container" >"${PACKAGE_FILE}"
		set -e

		log_console_info "Packages of all apps in the '${APP_GROUP}' group: ${PACKAGE_FILE}"

		rm -Rf "${APP_GROUP_TMP_DIR}"
	else
		log_console_warning "No Java binary application found. Skipping package analysis."
	fi
}

function extract_packages() {
	TRIGGER=${1}
	PACKAGE_FILE=${2}
	PACKAGES=false
	PACKAGE_COUNT=0
	find "${PACKAGE_DIR_OUT}" -maxdepth 1 -mindepth 1 -type f -name "*.txt" -exec cat "{}" \; -exec echo "${TOKEN}" \; |
		while read -r LINE; do
			[[ "${LINE}" == "${TRIGGER}" ]] && PACKAGES=true && continue
			[[ "${LINE}" == "${TOKEN}" ]] && PACKAGES=false && PACKAGE_COUNT=0 && continue
			[[ "${LINE}" == "Unknown Packages:" || "${LINE}" == "Known Packages:" ]] && PACKAGES=false && continue
			[[ "${LINE}" == "=======================" ]] && continue
			[[ -z "${LINE}" && ${PACKAGE_COUNT} -gt 0 ]] && PACKAGES=false && continue
			[[ "${PACKAGES}" == "true" ]] && echo "${LINE}" && ((PACKAGE_COUNT += 1))
		done |
		grep -Eo '^[^ ]+' | sort | uniq >"${PACKAGE_FILE}"
}

function main() {
	if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_WINDUP}") ]]; then
		# Trick to isolate the analyzed apps from the other folders
		rm -Rf "${APP_GROUP_TMP_DIR}" "${PACKAGE_DIR_OUT}"
		mkdir -p "${PACKAGE_DIR_OUT}"

		analyze_packages

		if [[ "${JAVA_BIN_APP_FOUND}" == "true" ]]; then
			extract_packages "Known Packages:" "${ALL_KNOWN_PACKAGES}"
			extract_packages "Unknown Packages:" "${ALL_UNKNOWN_PACKAGES}"
			cat "${ALL_KNOWN_PACKAGES}" "${ALL_UNKNOWN_PACKAGES}" | grep -Eo '^[^ ]+' | sort | uniq >"${ALL_PACKAGES}"

			COUNT_PACKAGES=$(wc -l <"${ALL_PACKAGES}" | tr -d ' ')
			COUNT_KNOWN_PACKAGES=$(wc -l <"${ALL_KNOWN_PACKAGES}" | tr -d ' ')
			COUNT_UNKNOWN_PACKAGES=$(wc -l <"${ALL_UNKNOWN_PACKAGES}" | tr -d ' ')

			EXCLUDED_PACKAGES="${CURRENT_DIR}/conf/Windup/exclude.packages"
			INCLUDED_PACKAGES="${CURRENT_DIR}/conf/Windup/include.packages"

			log_console ""
			log_console_success "Overview of the found Java packages:"
			log_console_sub_step "${COUNT_PACKAGES} packages in total ('${ALL_PACKAGES}')"
			log_console_sub_step "${COUNT_KNOWN_PACKAGES} known packages - those will be ignored ('${ALL_KNOWN_PACKAGES}')"
			log_console_sub_step "${COUNT_UNKNOWN_PACKAGES} unknown packages - those will be analyzed ('${ALL_UNKNOWN_PACKAGES}')"
			log_console ""

			if [[ ${COUNT_UNKNOWN_PACKAGES} -ne 0 ]]; then
				log_console_warning "For a quicker and more accurate analysis, please review the ${COUNT_UNKNOWN_PACKAGES} unknown Java packages, and consider adding some of them to either ..."
				log_console_sub_step "the list of the excluded packages ('${EXCLUDED_PACKAGES}') if they should be ignored (external libraries)"
				log_console_sub_step "the list of the all included packages ('${INCLUDED_PACKAGES}') to be analyzed and decompiled (self-written code)"
				log_console ""
			fi
		fi
	else
		log_console_error "Windup analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_WINDUP}'"
	fi
}

main
