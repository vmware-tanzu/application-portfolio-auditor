#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Install all prerequisites needed to run "Application Portfolio Auditor" on Ubuntu.
##############################################################################################################

# --- To be changed
set -x
export TIMEZONE='Europe/Berlin'

# --- Don't change
CURRENT_USER="$(whoami)"

# Use 'vagrant' as current user if the user exists
if id "vagrant" >/dev/null 2>&1; then
	CURRENT_USER='vagrant'
fi

export USER="${CURRENT_USER}"
export GROUP="${CURRENT_USER}"

export SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
export INSTALL_DIR="${SCRIPT_DIR}/../../../"

# Update the ulimits to be able to pass the Windup tests
function set_ulimit() {
	sudo tee -a /etc/sysctl.conf <<EOL
fs.file-max = 100000
EOL

	sudo tee -a /etc/security/limits.conf <<EOL
* soft nofile 100000
* hard nofile 100000
* soft nproc 100000
* hard nproc 100000
root soft nofile 100000
root hard nofile 100000
root soft nproc 100000
root hard nproc 100000
EOL

	sudo sysctl -p

	sudo tee -a /etc/pam.d/common-session* <<EOL
	session required pam_limits.so
	EOL

	sudo tee -a /etc/systemd/user.conf <<EOL
DefaultLimitNOFILE=100000
EOL
}

# Install Java JDK from https://jdk.java.net/20/
function setup_java() {
	ARCH=$(arch)
	JDK_URL=https://download.java.net/java/GA/jdk20.0.1/b4887098932d415489976708ad6d1a4b/9/GPL/openjdk-20.0.1_linux-x64_bin.tar.gz
	if [[ "${ARCH}" == "aarch64" ]]; then
		JDK_URL=https://download.java.net/java/GA/jdk20.0.1/b4887098932d415489976708ad6d1a4b/9/GPL/openjdk-20.0.1_linux-aarch64_bin.tar.gz
	fi
	JAVA_DIR="/java/jdk"
	sudo mkdir -p "${JAVA_DIR}"
	sudo chown -R "${USER}":"${GROUP}" "${JAVA_DIR}"
	cd "${JAVA_DIR}"
	wget -q "${JDK_URL}"
	tar xvzf openjdk-20.0.1_linux-*.tar.gz &>/dev/null
	rm openjdk-20.0.1_linux-*.tar.gz

	ln -s /java/jdk/jdk-20.0.1/bin/java /usr/bin/java
	ln -s /java/jdk/jdk-20.0.1/bin/javac /usr/bin/javac
	chmod +x /usr/bin/java /usr/bin/javac

	USER_HOME="$(eval echo ~${USER})"
	sudo tee -a "${USER_HOME}/.bashrc" <<EOL
export JAVA_HOME=/java/jdk/jdk-20.0.1
export PATH="\${JAVA_HOME}/bin:\${PATH}"
EOL
	source "${USER_HOME}/.bashrc"
}

# Install, enable, and start Docker (https://docs.docker.com/engine/install/ubuntu/)
function setup_docker() {
	# Uninstall old Docker versions
	sudo apt-get remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io
	sudo rm -rf /var/lib/docker /var/lib/containerd

	# Setup the Docker repository
	sudo apt-get install -y ca-certificates curl gnupg lsb-release
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

	# Install Docker Engine
	sudo apt-get update -y
	sudo apt-get install -y docker-ce docker-ce-cli containerd.io

	# Create the Docker group
	if [ ! "$(getent group docker)" ]; then
		sudo groupadd docker
	fi

	# Add current user to the docker group.
	sudo usermod -aG docker "${USER}"

	# Configure Docker to start on boot
	sudo systemctl enable docker.service
	sudo systemctl enable containerd.service

	# Start Docker
	sudo systemctl start docker

	# Clean up permissions
	if [[ "${USER}" != "root" ]]; then
		sudo chown -R "${USER}":"${GROUP}" "${INSTALL_DIR}"
		sudo chmod g+rwx "${USER_HOME}/.docker" -R
		sudo chmod 666 /var/run/docker.sock
	fi
}

# Main installation
function main() {
	# Update OS
	sudo apt-get update -y

	# Install required RPM dependencies
	sudo apt-get install -y lvm2 wget rsync net-tools unzip zip apt-transport-https ca-certificates curl gnupg lsb-release uidmap iputils-ping locales
	sudo apt-get install -y jq git libxml2-utils xsltproc

	# Install Java JDK
	setup_java

	## Configure the ulimit
	# set_ulimit

	# Install Docker
	setup_docker

	# Set timezone
	sudo ln -snf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime && echo "${TIMEZONE}" >/etc/timezone

	sudo locale-gen en_US.UTF-8
	update-locale LANG=en_US.UTF-8
}

main
