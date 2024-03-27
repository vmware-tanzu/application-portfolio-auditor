#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Library tracking versions of all used tools and frameworks.
##############################################################################################################

# Current version of Application Portfolio Auditor
export TOOL_VERSION='2.1.1'

# Java version used for Bagger and Fernflower
export JAVA_VERSION='20'

# List of the versions for all tools in use.

# Migration & cloud readiness
#export WINDUP_VERSION='6.3.0' - Visualization of new version is a step back.
export WINDUP_VERSION='6.1.11'
export CSA_VERSION='4.1.13'
export CSA_BAGGER_VERSION='1.0.1'
export WAMT_VERSION='24.0.0.1'

# Languages
export LINGUIST_VERSION='7.29.0'
export CLOC_VERSION='1.98'

# License & Authors
export SCANCODE_VERSION='32.0.8'

# Code quality / bugs
export MAI_VERSION='1.9.22'
export PMD_VERSION='7.0.0'
export JQA_VERSION='1.8.0'
export SCC_VERSION='2.12.0'

# Security
export OWASP_DC_VERSION='8.4.3'
export FSB_VERSION='1.12.0'
export SLSCAN_VERSION='2.1.1'
export INSIDER_VERSION='3.0.0'
export SYFT_VERSION='1.0.1'
export GRYPE_VERSION='0.74.7'
export TRIVY_VERSION='0.50.0'
export OSV_VERSION='1.7.0'
export BEARER_VERSION='1.43.0'

# Supporting frameworks
export MUSTACHE_VERSION='3.0.4'
export NIST_MIRROR_VERSION='1.6.0'
export D3_VERSION='7.9.0'
export JQUERY_VERSION='3.7.1'
export BOOTSTRAP_VERSION='5.3.3'
export BOOTSTRAP_ICONS_VERSION='1.11.3'
export TIMELINES_CHART_VERSION='2.12.1'

# Supporting container images

## Nginx runtime
export NGINX_VERSION='1.25.4'
export IMG_NGINX="nginx:${NGINX_VERSION}-alpine3.18"

## .NET runtime image used to build MAI and OWASP DC container images (https://mcr.microsoft.com/v2/dotnet/runtime/tags/list)
export DONET_RUNTIME_VERSION='8.0.3-alpine3.19'
export IMG_DOTNET_RUNTIME="mcr.microsoft.com/dotnet/runtime:${DONET_RUNTIME_VERSION}"

export IMG_ECLIPSE_TEMURIN_11="eclipse-temurin:11.0.22_7-jre"
export IMG_ECLIPSE_TEMURIN_21="eclipse-temurin:21.0.2_13-jre-alpine"
