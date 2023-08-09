#!/usr/bin/env bash
# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Bundle scripts and binaries in one zip distribution file for distribution in an air-gapped environment.
##############################################################################################################

export ARCH SCRIPT_DIR AUDITOR_DIR RELEASE_DIR TEST_APPLICATION TMP_DIR DATE

ARCH="$(uname -m)"
SCRIPT_DIR="$( cd -- "$(dirname "${0}" )" || exit >/dev/null 2>&1 ; pwd -P )"
AUDITOR_DIR="${SCRIPT_DIR}/../.."

#### Variables to be adjusted

# Output directory for the zipped binary release
RELEASE_DIR="${AUDITOR_DIR}/../application-portfolio-auditor-releases"

# Folder containing test application(s) to be included in the binary release
TEST_APPLICATION="${AUDITOR_DIR}/apps/test"

# Temporary directory to prepare the release
TMP_DIR="/tmp/application-portfolio-auditor"

# ------ Do not modify
DATE=$(date +%Y_%m_%d)

set -x

rm -Rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

rsync --exclude ".DS_Store" \
	--exclude ".git" \
	--exclude ".vagrant" \
	--exclude "/apps" \
	--exclude "/bin" \
	--exclude "/dist/bagger/target" \
	--exclude "/docs" \
	--exclude "/reports" \
	--exclude "/tmp" \
	--exclude "/work-in-progress" \
	-avh --quiet --no-perms "${AUDITOR_DIR}/" "${TMP_DIR}/."

pushd "${TMP_DIR}" &>/dev/null || exit

# Cleanup
rm -Rf dist/containerized/cloc/ dist/containerized/windup/Dockerfile-windup-with-user.mo dist/containerized/windup/windup-cli-append-debug
rm -Rf conf/CSA/default-rules/*.yaml conf/CSA/*.yaml
rm -Rf .git .gitignore

# Remove .DS_Store files
find . -name '.DS_Store' -type f -delete
find dist/containerized/. \( -name '*.zip' -o -name '*.orig' \) -type f -delete

mkdir -p apps bin reports

# Add test application
cp -Rfp "${TEST_APPLICATION}" apps/.

cd .. || exit

# Zip all script and binaries
zip -r "application-portfolio-auditor__${DATE}.zip" application-portfolio-auditor >>/dev/null 2>&1

mkdir -p "${RELEASE_DIR}"

# Generate a formatted list of files for comparison purposes
unzip -l "application-portfolio-auditor__${DATE}.zip" | sed '1,2d;$d' | awk '{ print $4 " - Size:" $1}' | tail -n +2 | tail -r | tail -n +2 | tail -r | sort >"${RELEASE_DIR}/application-portfolio-auditor__${ARCH}__${DATE}.zip.txt"

mv "application-portfolio-auditor__${DATE}.zip" "${RELEASE_DIR}/application-portfolio-auditor__${ARCH}__${DATE}.zip"

popd &>/dev/null || exit

rm -Rf "${TMP_DIR}"

set +x

echo "(${DATE}) Tools bundled: ${RELEASE_DIR}"
