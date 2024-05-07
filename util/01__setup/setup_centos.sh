#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Install all prerequisites needed to run "Application Portfolio Auditor" on CentOS.
##############################################################################################################

# --- To be changed
set -x

# --- Don't change
CURRENT_USER="$(whoami)"

echo "setup_centos.sh"

# Use 'vagrant' as current user if the user exists
if id "vagrant" >/dev/null 2>&1; then
	CURRENT_USER='vagrant'
fi

export USER="${CURRENT_USER}"
export GROUP="${CURRENT_USER}"

export SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
export BASE_DIR="${SCRIPT_DIR}/../../../"

# Update the ulimits to be able to pass the Windup tests
function set_ulimit() {
	export ULIMIT_FILE_DEST='/etc/security/limits.d/nofile.conf'
	cat >>'nofile.conf' <<EOF
*    soft    nofile 100000
*    hard    nofile 100000
EOF
	sudo mv 'nofile.conf' ${ULIMIT_FILE_DEST}
	sudo chown root:root ${ULIMIT_FILE_DEST}
	sudo chmod 0644 ${ULIMIT_FILE_DEST}
}

# Install, enable, and start Docker (https://docs.docker.com/engine/install/ubuntu/)
function setup_docker() {
	# Uninstall old Docker versions (incl. runc, podman, skopeo ...)
	sudo yum -y remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
	sudo yum -y remove buildah skopeo podman containers-common atomic-registries container-tools runc
	sudo rm -rf /etc/containers/* /var/lib/containers/* /etc/docker /etc/subuid* /etc/subgid*

	# Setup the Docker repository
	sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

	# Install Docker Engine
	sudo yum -y install docker-ce docker-ce-cli containerd.io

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
}

# Main installation
function main() {
	# Update OS
	sudo yum -y update

	# Install required RPM dependencies
	sudo yum -y install lvm2 wget rsync net-tools curl jq unzip git yum-utils snapd

	# Install libxml2-utils and xsltproc
	sudo systemctl enable --now snapd.socket
	sudo ln -s /var/lib/snapd/snap /snap
	sudo snap install libxml2-utils
	sudo dnf -y install libxslt

	## Configure the ulimit
	# set_ulimit

	# Install Docker
	setup_docker

	## Clean up permissions
	if [[ "${USER}" != "root" ]]; then
		sudo chown -R "${USER}":"${GROUP}" "${BASE_DIR}" &>/dev/null
	fi
}

main
