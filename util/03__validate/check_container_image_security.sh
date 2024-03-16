#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Check the security of the built container images using local Trivy analyzer
##############################################################################################################

# Directories
readonly DIST_DIR="$(dirname "${BASH_SOURCE[0]}")/../../dist"
readonly OUT_DIR="${DIST_DIR}/containerized_security_reports"
readonly SUMMARY_FILE="${OUT_DIR}/_trivy_summary.txt"

# Colors
readonly RED='\033[0;31m'
readonly NORMAL='\033[0m'

function main {

	if [[ -z "$(command -v trivy)" ]]; then
		if [[ "${IS_MAC}" == "true" ]]; then
			echo -e "${RED}Local 'trivy' installation is not available. Please install it ([MacOS] '$ brew install trivy') to use this functionality.${NORMAL}"
		else
			echo -e "${RED}Local 'trivy' installation is not available. Please install it to use this functionality.${NORMAL}"
		fi
		exit 1
	fi

	rm -Rf "${OUT_DIR}"
	mkdir -p "${OUT_DIR}"
	while read -r IMG; do
		local IMG_NAME=$(basename "${IMG}")
		local OUT_FILE="${OUT_DIR}/_trivy_scan__${IMG_NAME}.txt"
		trivy image --input "${IMG}" --no-progress --scanners "vuln,config,secret" --quiet -f table >"${OUT_FILE}"
		printf '\n%s\n' "${IMG_NAME}" >>"${SUMMARY_FILE}"
		grep "^Total: " "${OUT_FILE}" >>"${SUMMARY_FILE}"
	done < <(find "${DIST_DIR}" -maxdepth 1 -mindepth 1 -type f -name 'oci__*.img' | sort)

	echo "Trivy analysis reports generated."
	echo "  >>> Summary: ${SUMMARY_FILE}"
	echo "  >>> Result directory: ${OUT_DIR}"
}

main
