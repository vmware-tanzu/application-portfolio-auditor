#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Install all prerequisites needed to run "Application Portfolio Auditor" on MacOS.
##############################################################################################################

# --- To be changed
export JAVA_VERSION=20

# --- Don't change
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

# Install brew and xcode CLI (echo -e "\n")
if type brew >/dev/null; then
	echo ">>> Already installed: brew"
else
	echo '>>> Installing brew - The Missing Package Manager for macOS'
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install a compativle Bash version if necessary
MAJOR_BASH_VERSION=$(echo "${BASH_VERSION}" | cut -d . -f 1)
if ((MAJOR_BASH_VERSION < 4)); then
	echo '>>> Installing: bash (latest)'
	brew install bash
	# Set latest bash as default
	BASH_VERSION=$(brew list --versions bash | sort | tail -1 | cut -d ' ' -f 2)
	BASH_LINK="$(brew --cellar)/bash/${BASH_VERSION}/bin/bash"

	SHELLS="/etc/shells"
	if ! grep -q "${BASH_LINK}" "${SHELLS}"; then
		sudo bash -c "echo ${BASH_LINK} >> /etc/shells"
		chsh -s "${BASH_LINK}"
	fi
else
	echo ">>> Already installed: bash"
fi

BREW_DEPENDENCIES=('gnu-getopt' 'curl' 'wget' 'unzip' 'maven' 'jq' 'md5sha1sum' 'git')

for DEPENDENCY in "${BREW_DEPENDENCIES[@]}"; do
	if brew list "${DEPENDENCY}" &>/dev/null; then
		echo ">>> Already installed: ${DEPENDENCY}"
	else
		echo ">>> Installing: ${DEPENDENCY}"
		brew install --force -q "${DEPENDENCY}"
	fi
done

if type docker >/dev/null; then
	echo ">>> Already installed: docker"
else
	echo ">>> Installing: docker"
	brew install --cask docker
	open /Applications/Docker.app
fi

# Install sdkman
SDKMAN_INIT="${HOME}/.sdkman/bin/sdkman-init.sh"
if [[ -f "${SDKMAN_INIT}" ]]; then
	echo ">>> Already installed: sdkman"
else
	echo ">>> Installing: sdkman"
	curl -s "https://get.sdkman.io" | bash
fi

# Install latest compatible required Java version
source "${SDKMAN_INIT}"
JAVA_LATEST=$(sdk ls java | grep -v sdk | grep tem | grep "${JAVA_VERSION}." | sort | tail -1 | tr -d ' ' | rev | cut -d '|' -f 1 | rev)
sdk install java "${JAVA_LATEST}"
sdk current java "${JAVA_LATEST}"

## Todo: Catch exception and provide guidant to fix potential permission issues on sdkman/docker directories
# echo 'sudo chown -R  $(id -u):$(id -g) "${HOME}/.sdkman/" "${HOME}/.docker/"'