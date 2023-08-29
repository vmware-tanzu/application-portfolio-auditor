#!/usr/bin/env bash
# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Library consolidating heavily reused functions and variables across "Application Portfolio Auditor".
##############################################################################################################

# Container engine in use - choose between podman and docker
export CONTAINER_ENGINE="docker"

# ------ Do not modify

# Argument for the container engine execution
case "${CONTAINER_ENGINE}" in
"podman")
	export CONTAINER_ENGINE_ARG="--privileged"
	export CONTAINER_ENGINE_SOCK=""
	;;
*)
	export CONTAINER_ENGINE_ARG=""
	export CONTAINER_ENGINE_SOCK="-v /var/run/docker.sock:/var/run/docker.sock"
	;;
esac

export GREEN RED ORANGE BLUE N B

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
BLUE='\033[1;34m'
N='\033[0m' # aka. 'NORMAL' 'NC' no color
B='\033[1m' # aka. 'BOLD'

function log_tool_start() {
	set -u
	local LOG_DATE
	LOG_DATE="$(date +%Y_%m_%d__%H_%M_%S)"
	echo ">>>>>>> [${LOG_DATE}] ${*}" >>"${RUN_LOG}"
	echo ">>>>>>> [${LOG_DATE}] ${*}" >>"${TIMELINE_LOG}"
	echo -e "${B}>>>>>>> [${LOG_DATE}] ${*}${N}"
}

function log_tool_end() {
	set -u
	local LOG_DATE
	LOG_DATE="$(date +%Y_%m_%d__%H_%M_%S)"
	echo -e "<<<<<<< [${LOG_DATE}] ${*}\n" >>"${RUN_LOG}"
	echo -e "<<<<<<< [${LOG_DATE}] ${*}\n" >>"${TIMELINE_LOG}"
	echo -e "${B}<<<<<<< [${LOG_DATE}] ${*}\n${N}"
}

function log_tool_info() {
	set -u
	echo -e "${BLUE}${*}${N}"
	echo "${*}" >>"${LOG_FILE}"
}

function log_analysis_message() {
	set -u
	echo " -> Analyzing ${*} ..." | tee -a "${LOG_FILE}"
}

function log_extract_message() {
	set -u
	echo " -> Extracting results from ${*} ..." | tee -a "${LOG_FILE}"
}

function log_console() {
	echo -e "${*}" | tee -a "${LOG_FILE}"
}

function log_console_step() {
	log_console " -> ${*}"
}

function log_console_sub_step() {
	log_console "     - ${*}"
}

function log_console_info() {
	log_console "    [INFO] ${*}"
}

function log_console_error() {
	echo "    [ERROR] ${*}" >>"${LOG_FILE}"
	echo -e "${RED}    [ERROR] ${*}${N}"
}

function log_warning() {
	echo "${*}" >>"${LOG_FILE}"
	echo -e "${ORANGE}${*}${N}"
}

function log_console_warning() {
	log_warning "    [WARNING] ${*}"
}

function log_console_success() {
	echo "    [SUCCESS] ${*}" >>"${LOG_FILE}"
	echo -e "${GREEN}    [SUCCESS] ${*}${N}"
}

function stream_edit() {
	if [[ "${IS_MAC}" == "true" ]]; then
		sed -i '' -e "${1}" "${2}"
	else
		sed -i -e "${1}" "${2}"
	fi
}

function for_each_group() {
	while read -r DIR; do
		GROUP_NAME="$(basename "${DIR}")"
		if [[ -z "${TARGET_GROUP}" || "${GROUP_NAME}" == "${TARGET_GROUP}" ]]; then
			"${@}" "${DIR}"
		fi
	done < <(find "${APP_DIR_IN}" -maxdepth 1 -mindepth 1 -type d | sort)
}

function get_step() {
	([[ ${0} != "${BASH_SOURCE[0]}" ]] && SCRIPT="${BASH_SOURCE[0]}") || SCRIPT="${0}"
	basename "${SCRIPT}" | cut -d'_' -f1
}

function count_lines() {
	wc -l <"${1}" | tr -d ' '
}
