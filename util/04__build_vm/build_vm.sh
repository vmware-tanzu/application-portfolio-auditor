#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Test the "Application Portfolio Auditor" setup on a Virtual Machine (VM).
#
# This script leverages Vagrant, Ansible and virtualization software to:
#  1. Create a Virtual Machine (VM)
#  2. Upload the latest distribution of "Application Portfolio Auditor"
#  3. Install all prerequisites leveraging the provided "01__setup" script
#  4. Generate, zip and retrieve a sample test report
#
# Note: In case of issue with the VMware utility driver, run: "brew reinstall --cask vagrant-vmware-utility
##############################################################################################################

# --- To be changed

## Set the Operating System of the VM image you want to build
TARGET_OS=Amazon
#TARGET_OS=Ubuntu
#TARGET_OS=CentOS

## Point to the latest local "Applicaton Portfolio Auditor" distribution - Please update!
SCRIPT_DIR="$(
	cd -- "$(dirname "${0}")" || exit >/dev/null 2>&1
	pwd -P
)"
DIST_FOLDER="${SCRIPT_DIR}/../../../application-portfolio-auditor-releases"

# --- Don't change
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
ARCH="$(uname -m)"
export DIST_ZIP="${DIST_FOLDER}/application-portfolio-auditor__${ARCH}__$(date +"%Y_%m_%d").zip"

# Define a function to run Vagrant with a specified Vagrantfile
function run_vagrant {

	FILE="Vagrantfile-$1"
	if [[ "${ARCH}" == "arm64" ]]; then
		FILE="$FILE-ARM"
	fi

	echo "export VAGRANT_VAGRANTFILE='$FILE'"
	export VAGRANT_VAGRANTFILE="$FILE"

	pushd "${SCRIPT_DIR}" &>/dev/null
	vagrant destroy -f
	vagrant up
	popd &>/dev/null
}

if [[ -f "${DIST_ZIP}" ]]; then
	# Call the function with each Vagrantfile
	run_vagrant "${TARGET_OS}"
else
	echo "No available packaged distribution of 'Application Portfolio Auditor' (${DIST_ZIP})"
	echo "  Package the current distribution with: $ ./audit package"
fi
