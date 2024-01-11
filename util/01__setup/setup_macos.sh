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

# Update the ulimits to be able to pass the Windup tests
# More information: https://stackoverflow.com/questions/3166783/how-to-increase-the-limit-of-maximum-open-files-in-c-on-mac-os-x
function set_ulimit() {
	echo "Updating the ulimits on OSX to be able to pass the Windup tests."
	sudo bash -c 'cat >/Library/LaunchDaemons/limit.maxfiles.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>limit.maxfiles</string>
    <key>ProgramArguments</key>
    <array>
      <string>launchctl</string>
      <string>limit</string>
      <string>maxfiles</string>
      <string>524288</string>
      <string>524288</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ServiceIPC</key>
    <false/>
  </dict>
</plist>
EOF'

	sudo bash -c 'cat >/Library/LaunchDaemons/limit.maxproc.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple/DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
    <dict>
      <key>Label</key>
        <string>limit.maxproc</string>
      <key>ProgramArguments</key>
        <array>
          <string>launchctl</string>
          <string>limit</string>
          <string>maxproc</string>
          <string>2048</string>
          <string>2048</string>
        </array>
      <key>RunAtLoad</key>
        <true />
      <key>ServiceIPC</key>
        <false />
    </dict>
  </plist>
EOF'

	sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist
	sudo launchctl load -w /Library/LaunchDaemons/limit.maxproc.plist
	echo "Please restart your system to make the changes effective."
}

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
	brew install bash
	# Set latest bash as default
	BASH_VERSION=$(brew list --versions bash | sort | tail -1 | cut -d ' ' -f 2)
	BASH_LINK="/usr/local/Cellar/bash/${BASH_VERSION}/bin/bash"
	SHELLS="/etc/shells"
	if ! grep -q "${BASH_LINK}" "${SHELLS}"; then
		sudo bash -c "echo ${BASH_LINK} >> /etc/shells"
		chsh -s "${BASH_LINK}"
	fi
else
	echo ">>> Already installed: bash"
fi

declare -A required_brew
required_brew['getopt']='gnu-getopt'
required_brew['curl']='curl'
required_brew['wget']='wget'
required_brew['unzip']='unzip'
required_brew['jq']='jq'
required_brew['sha1sum']='md5sha1sum'
required_brew['git']='git'

# Install getopt, curl, wget, bash, jq, md5sha1sum, git
for i in "${!required_brew[@]}"; do
	command="${i}"
	software="${required_brew[$i]}"
	if type "${command}" >/dev/null; then
		echo ">>> Already installed: ${software}"
	else
		echo ">>> Installing ${software}"
		brew install "${software}"
	fi
done

if type docker >/dev/null; then
	echo ">>> Already installed: docker"
else
	brew install --cask docker
	open /Applications/Docker.app
fi

# Install sdkman
SDKMAN_INIT="${HOME}/.sdkman/bin/sdkman-init.sh"
if [[ -f "${SDKMAN_INIT}" ]]; then
	echo ">>> Already installed: sdkman"
else
	echo "Install sdk"
	curl -s "https://get.sdkman.io" | bash
fi

# Install latest compatible required Java version
source "${SDKMAN_INIT}"
JAVA_LATEST=$(sdk ls java | grep -v sdk | grep tem | grep "${JAVA_VERSION}." | sort | tail -1 | tr -d ' ' | rev | cut -d '|' -f 1 | rev)
sdk install java "${JAVA_LATEST}"
sdk default java "${JAVA_LATEST}"

## Configure the ulimit
# set_ulimit
