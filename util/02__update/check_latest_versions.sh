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

PYTHON_CMD_FULL=$(command -v python3 || command -v python)

if [[ -z "${PYTHON_CMD_FULL}" ]]; then
	echo "This feature requires 'python' to be installed. Please install python and retry."
	exit 1
fi

PYTHON_CMD=$(basename "${PYTHON_CMD_FULL}")

# Create a Python virtual environment
VENV_DIR="${SCRIPT_DIR}/.venv"
if [[ ! -d "${VENV_DIR}" ]]; then
	echo "Creating Python virtual environment..."
	${PYTHON_CMD_FULL} -m venv "${VENV_DIR}"
fi

# Activate the virtual environment
source "${VENV_DIR}/bin/activate"

# Upgrade pip and import all required python libraries
${PYTHON_CMD} -m pip --quiet install --upgrade pip
${PYTHON_CMD} -m pip --quiet install BeautifulSoup4 requests aiohttp

# Load the current version numbers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../../_versions.sh"

# Check for new versions
# shellcheck source=/dev/null
${PYTHON_CMD} "${SCRIPT_DIR}/check_latest_versions.py"

# Deactivate the virtual environment
deactivate
