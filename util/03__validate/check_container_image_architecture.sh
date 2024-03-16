#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Check the processor architectures (e.g. x86/ARM/x64) supported by the built container images.
##############################################################################################################

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly NORMAL='\033[0m'

# Hardware architecture of the current machine
readonly ARCH="$(uname -m)"

# Directories
readonly DIST_DIR="$(dirname "${BASH_SOURCE[0]}")/../../dist"
readonly TMP_DIR="/tmp/d_tmp"

function main {
	rm -Rf ${TMP_DIR}
	while read -r IMG; do
		mkdir -p ${TMP_DIR}
		tar -xf "${IMG}" -C ${TMP_DIR} $(tar -tf "${IMG}" | grep -E '\.json$')
		local IMG_NAME=$(jq -M '.[].RepoTags[0]' ${TMP_DIR}/manifest.json | tr -d '"')
		local IMG_PLATFORM

		if [[ -f "${TMP_DIR}/index.json" ]]; then
			IMG_PLATFORM=$(jq -M '.manifests[0].platform.architecture' "${TMP_DIR}/index.json" | tr -d '"')
		else
			local IMG_PLATFORM_JSON=$(find ${TMP_DIR} | grep -E '.{64}\.json$')
			if [[ ! -z "${IMG_PLATFORM_JSON}" ]]; then

				IMG_PLATFORM=$(jq -M '.architecture' "${IMG_PLATFROM_JSON}" | tr -d '"')
			fi
		fi

		if [[ "${ARCH}_${IMG_PLATFORM}" == "arm64_arm64" ]] || [[ "${ARCH}_${IMG_PLATFORM}" == "x86_64_amd64" ]]; then
			echo -e "${GREEN}${IMG_PLATFORM}${NORMAL} - ${IMG_NAME}"
		else
			echo -e "${RED}${IMG_PLATFORM}${NORMAL} - ${IMG_NAME}"
		fi
		rm -Rf ${TMP_DIR}

	done < <(find "${DIST_DIR}" -maxdepth 1 -mindepth 1 -type f -name 'oci*.img' | sort)
}

main
