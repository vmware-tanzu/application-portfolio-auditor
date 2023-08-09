#!/usr/bin/env bash
# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Library tracking versions of all used tools and frameworks.
##############################################################################################################

# Java version used for Bagger and Fernflower
export JAVA_VERSION='17'

# Current version of Application Portfolio Auditor
export TOOL_VERSION='2.0.0'

# List of the versions for all tools in use.

# Migration & cloud readiness
#export WINDUP_VERSION='6.3.0' - Visualization of new version is a step back.
export WINDUP_VERSION='6.1.11'
export CSA_VERSION='4.0.0'
export WAMT_VERSION='23.0.0.2'

# Languages
export LINGUIST_VERSION='7.26.0'
export CLOC_VERSION='1.96'

# License & Authors
#export SCANCODE_VERSION='32.0.4' - Latest version does not detect all licenses / copyrights.
export SCANCODE_VERSION='31.2.6'

# Code quality / bugs
export MAI_VERSION='1.9.10'
export PMD_VERSION='6.55.0'
export JQA_VERSION='1.8.0'
export SCC_VERSION='2.12.0'

# Security
export PMD_GDS_VERSION='2.33.0'
export OWASP_DC_VERSION='8.3.1'
export FSB_VERSION='1.12.0'
export SLSCAN_VERSION='2.1.1'
export INSIDER_VERSION='3.0.0'
export SYFT_VERSION='0.86.1'
export GRYPE_VERSION='0.65.1'
export TRIVY_VERSION='0.44.0'

# Other
export MUSTACHE_VERSION="3.0.2"
export NGINX_VERSION="1.25.1"
export NIST_MIRROR_VERSION="1.6.0"
export D3_VERSION="7.8.5"
export JQUERY_VERSION="3.7.0"
export BOOTSTRAP_VERSION="5.3.1"
export BOOTSTRAP_ICONS_VERSION="1.10.5"
export TIMELINES_CHART_VERSION="2.12.1"
