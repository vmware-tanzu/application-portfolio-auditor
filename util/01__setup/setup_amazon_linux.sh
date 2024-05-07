#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Install all prerequisites needed to run "Application Portfolio Auditor" on Amazon Linux.
##############################################################################################################

# --- To be changed
set -x

# --- Don't change
CURRENT_USER="$(whoami)"

echo "setup_amazon_linux.sh"

# Use 'vagrant' as current user if the user exists
if id "vagrant" >/dev/null 2>&1; then
	CURRENT_USER='vagrant'
fi

export USER="${CURRENT_USER}"
export GROUP="${CURRENT_USER}"

export SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
export BASE_DIR="${SCRIPT_DIR}/../../../"

# Install, enable, and start Docker (https://docs.docker.com/engine/install/ubuntu/)
function setup_docker() {

	# https://www.cyberciti.biz/faq/how-to-install-docker-on-amazon-linux-2/

	# Setup the Docker repository
	sudo yum -y install docker

	# Create the Docker group
	if [ ! "$(getent group docker)" ]; then
		sudo groupadd docker
	fi

	# Add current user to the docker group.
	sudo usermod -aG docker "${USER}"

	# Configure Docker to start on boot
	sudo systemctl enable docker.service
	sudo systemctl start docker.service

}

# Main installation
function main() {

	# Update OS
	sudo yum -y update

	# Install required RPM dependencies
	sudo yum -y install --skip-broken lvm2 wget rsync net-tools jq unzip git yum-utils

	# Install snapd to install libxml2-utils and xsltproc
	sudo wget -O /etc/yum.repos.d/snapd.repo https://bboozzoo.github.io/snapd-amazon-linux/al2023/snapd.repo
	sudo dnf install snapd -y

	# Install libxml2-utils and xsltproc
	sudo systemctl enable --now snapd.socket
	sudo systemctl restart snapd.seeded.service
	sudo ln -s /var/lib/snapd/snap /snap
	sudo snap install libxml2-utils
	sudo dnf -y install libxslt

	# Install Docker
	setup_docker

	## Clean up permissions
	if [[ "${USER}" != "root" ]]; then
		sudo chown -R "${USER}":"${GROUP}" "${BASE_DIR}" &>/dev/null
	fi
}

main