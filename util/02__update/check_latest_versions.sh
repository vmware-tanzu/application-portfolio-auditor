#!/usr/bin/env bash
# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Check available updates for each tool used by "Application Portfolio Auditor".
#
# This script calls a python script (check_latest_versions.py) and requires python 3.7+ and pip.
##############################################################################################################

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

# Import all required python libraries
pip install bs4 requests aiohttp >>/dev/null

# Load the current version numbers
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../../_versions.sh"

# Check for new versions
# shellcheck source=/dev/null
python "${SCRIPT_DIR}/check_latest_versions.py"
