#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Library consolidating heavily reused functions and variables across "Application Portfolio Auditor".
##############################################################################################################

# Container engine in use - choose between podman and docker
export CONTAINER_ENGINE="docker"
# Removing CLI hints for docker
export DOCKER_CLI_HINTS=false

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

function echo_console_warning() {
	echo -e "${ORANGE}${*}${N}"
}

function echo_console_error() {
	echo -e "${RED}${*}${N}"
}

function echo_console_tool_info() {
	echo -e "${BLUE}${*}${N}"
}

function log_tool_info() {
	set -u
	echo_console_tool_info "${*}"
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

function log_warning() {
	echo "${*}" >>"${LOG_FILE}"
	echo_console_warning "${*}"
}

function log_error() {
	echo "${*}" >>"${LOG_FILE}"
	echo_console_error "${*}"
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
	log_error "    [ERROR] ${*}"
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

function get_step() {
	([[ ${0} != "${BASH_SOURCE[0]}" ]] && SCRIPT="${BASH_SOURCE[0]}") || SCRIPT="${0}"
	basename "${SCRIPT}" | cut -d'_' -f1
}

function count_lines() {
	wc -l <"${1}" | tr -d ' '
}

function check_debug_mode() {
	if [[ "${DEBUG}" == "true" ]]; then
		set -x
		exec 6>&1
	else
		exec 6>/dev/null
	fi
}
