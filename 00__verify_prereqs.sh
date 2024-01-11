#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Validate additional prerequisites for a seamless analysis
#
# Those validations are done afer "00_unpack_all_tools" has been run.
##############################################################################################################

# ------ Do not modify
export LOG_FILE=/dev/null

# 02 - Validate that CSA is working properly.
# Catching up exceptions looking like "/csa-l: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.28' not found (required by ./csa-l)"
if [[ "${CSA_ACTIVE}" == "true" ]]; then
	log_console_step "Step 02 - Check further CSA prerequisites"
	CSA_DIR=${INSTALL_DIR}/cloud-suitability-analyzer
	CSA=${CSA_DIR}/csa-l
	if [ "${IS_MAC}" == "true" ]; then
		CSA=${CSA_DIR}/csa
	fi
	set +e
	"${CSA}" --version >/dev/null 2>&1
	RC=$?
	if [[ ${RC} -ne 0 ]]; then
		if [[ "${IS_MAC}" == "true" ]]; then
			log_console_error "Error while testing CSA (${RC}). Please verify your setup and restart the analysis."
		else
			# Execute a second time showing the error message
			printf '\033[0;31m'
			"${CSA}" --version >/dev/null
			printf '\033[0m'
			log_console_error "Error while testing CSA (${RC}).
	[Ubuntu] Make sure the latest version of GLIBC is available:
		$ curl http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6_2.29-0ubuntu2_amd64.deb --output libc6.deb
		$ sudo dpkg -i libc6.deb --auto-deconfigure
		$ rm libc6.deb"
		fi
		set -e
		exit 1
	fi
	set -e
fi
