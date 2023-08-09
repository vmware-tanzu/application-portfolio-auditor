#!/usr/bin/env bash
# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Cleanup all "src" and "tmp" sub-directories of the "apps" folder.
##############################################################################################################

export SCRIPT_DIR HOME_DIR

SCRIPT_DIR="$( cd -- "$(dirname "${0}" )" || exit >/dev/null 2>&1 ; pwd -P )"
APP_DIR="${SCRIPT_DIR}/../../apps"

pushd "${APP_DIR}" || exit &>/dev/null

echo "--- [INFO] Removing the following 'src' and 'tmp' directories:"
find . -maxdepth 2 -mindepth 2 -type d \( -name "tmp" -o -name "src" \) -exec sh -c 'echo "$0"' {} \;
echo "--- [INFO] Deletion in progress..."
find . -maxdepth 2 -mindepth 2 -type d \( -name "tmp" -o -name "src" \) -exec sh -c 'rm -Rf "$0"' {} \;
echo "--- [INFO] Cleanup completed!"

popd || exit &>/dev/null
