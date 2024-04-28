#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Check available updates for each tool used by "Application Portfolio Auditor".
#
# This script calls a python script (check_latest_versions.py) and requires python 3.7+ and pip.
##############################################################################################################

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

# Load shared functions for console logging
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../_shared_functions.sh"

PYTHON_CMD=$(command -v python || command -v python3)
PIP_CMD=$(command -v pip || command -v pip3)

if [[ -z "${PYTHON_CMD}" ]] || [[ -z "${PIP_CMD}" ]]; then
	[[ -z "${PYTHON_CMD}" ]] && echo_console_error "'python' is not available. Please install it."
	[[ -z "${PIP_CMD}" ]] && echo_console_error "'pip' is not available. Please install it."
	exit 1
fi

# Import all required python libraries
${PIP_CMD} install bs4 requests aiohttp --break-system-packages >>/dev/null

# Load the current version numbers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../../_versions.sh"

# Check for new versions
# shellcheck source=/dev/null
${PYTHON_CMD} "${SCRIPT_DIR}/check_latest_versions.py"
