#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Unpack all tools.
##############################################################################################################

export LOG_FILE=/dev/null

if [[ -d "${INSTALL_DIR}" ]]; then

	# Check if a marker file is present
	COUNT_MARKERS=$(find "${INSTALL_DIR}" -maxdepth 1 -mindepth 1 -name "tools_*unpacked" -type f | wc -l)
	if ((COUNT_MARKERS > 0)); then
		# Skip unpacking
		log_console_info "Skipping unpacking: all tools already extracted."
		return
	fi
	rm -Rf "${INSTALL_DIR}"
fi

mkdir -p "${INSTALL_DIR}"

for TOOL in "${DIST_DIR}"/*.zip; do
	# Extract only the "macos" / "apple" zip files on MacOS and the "linux" ones on Linux.
	TO_EXTRACT="false"
	if (echo "${TOOL}" | grep -q 'macos') || (echo "${TOOL}" | grep -q 'apple'); then
		if [[ "${IS_MAC}" == "true" ]]; then
			TO_EXTRACT="true"
		fi
	elif echo "${TOOL}" | grep -q 'linux'; then
		if [[ "${IS_LINUX}" == "true" ]]; then
			TO_EXTRACT="true"
		fi
	else
		TO_EXTRACT="true"
	fi

	if [[ "${TO_EXTRACT}" == "true" ]]; then
		log_console_step "Unzipping '$(basename "${TOOL}")'"
		unzip "${TOOL}" -d "${INSTALL_DIR}" >/dev/null 2>&1
	fi
done

for TOOL in "${DIST_DIR}"/*.t*gz; do
	log_console_step "Untarring '$(basename "${TOOL}")'"
	tar -xzf "${TOOL}" -C "${INSTALL_DIR}" >/dev/null 2>&1
done

while read -r TOOL; do
	log_console_step "Copying '$(basename "${TOOL}")'"
	cp -Rfp "${TOOL}" "${INSTALL_DIR}/." >/dev/null 2>&1
done < <(find "${DIST_DIR}" -maxdepth 1 -mindepth 1 -type d -name templating)

for TOOL in "${DIST_DIR}"/*.jar; do
	log_console_step "Copying '$(basename "${TOOL}")'"
	cp -f "${TOOL}" "${INSTALL_DIR}/." >/dev/null 2>&1
done

# Make 'findsecbugs.sh' executable
FSB="${INSTALL_DIR}/findsecbugs-cli-${FSB_VERSION}/findsecbugs.sh"
if [ -f "${FSB}" ]; then
	chmod +x "${FSB}"
fi

# Creates a marker file with timestamp to skip the next unpacking.
touch "${INSTALL_DIR}/tools_${TIMESTAMP}.unpacked"

if [[ "$(uname)" == "Darwin" ]]; then
	log_console_step "Disabling Mac OS quarantine flag for for all tools"
	xattr -r -d com.apple.quarantine "${INSTALL_DIR}" || true
fi

# Copies GDS-PMD-Security-Rules
mv "${INSTALL_DIR}/pmd-gds-${PMD_GDS_VERSION}.jar" "${INSTALL_DIR}/pmd-bin-${PMD_VERSION}/lib/."

# Copies additional required libraries for PMD
mv "${INSTALL_DIR}/pmd-missing-commons-compiler-3.1.7.jar" "${INSTALL_DIR}/pmd-bin-${PMD_VERSION}/lib/."
mv "${INSTALL_DIR}/pmd-missing-jakarta.activation-2.0.1.jar" "${INSTALL_DIR}/pmd-bin-${PMD_VERSION}/lib/."
mv "${INSTALL_DIR}/pmd-missing-jakarta.activation-api-1.2.2.jar" "${INSTALL_DIR}/pmd-bin-${PMD_VERSION}/lib/."
mv "${INSTALL_DIR}/pmd-missing-jakarta.mail-api-1.6.7.jar" "${INSTALL_DIR}/pmd-bin-${PMD_VERSION}/lib/."
mv "${INSTALL_DIR}/pmd-missing-janino-3.1.7.jar" "${INSTALL_DIR}/pmd-bin-${PMD_VERSION}/lib/."
mv "${INSTALL_DIR}/pmd-missing-mailapi-2.0.1.jar" "${INSTALL_DIR}/pmd-bin-${PMD_VERSION}/lib/."
