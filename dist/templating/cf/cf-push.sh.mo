#!/usr/bin/env bash
# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

CF_APP_NAME={{CF_APP_NAME}}
CF_CLI_VERSION=$(cf version | cut -d' ' -f 3 | head -c 1)

if [[ "${CF_CLI_VERSION}" == "7" ]]; then
	cf d -f "${CF_APP_NAME}"
	cf create-app "${CF_APP_NAME}"
	cf apply-manifest -f manifest.yml
	cf push "${CF_APP_NAME}"
else
	echo "Invalid CF CLI version. Please install CF CLI v7 following instructions on https://github.com/cloudfoundry/cli"
fi

