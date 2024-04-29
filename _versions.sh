#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Library tracking versions of all used tools and frameworks.
##############################################################################################################

# Current version of Application Portfolio Auditor
export TOOL_VERSION='2.2.1'

# List of the versions for all tools in use.

## Migration & cloud readiness
export WINDUP_VERSION='6.1.11'
export CSA_VERSION='4.1.15'
export CSA_BAGGER_VERSION='1.0.3'
export WAMT_VERSION='24.0.0.1'

## Languages
export LINGUIST_VERSION='7.29.0'
export CLOC_VERSION='2.00'

## License & Authors
export SCANCODE_VERSION='32.1.0'

## Code quality / bugs
export MAI_VERSION='1.9.22'
export PMD_VERSION='7.1.0'
export JQA_VERSION='1.8.0'
export SCC_VERSION='2.12.0'

## Security
export OWASP_DC_VERSION='8.4.3'
export FSB_VERSION='1.12.0'
export SLSCAN_VERSION='2.1.1'
export INSIDER_VERSION='3.0.0'
export TRIVY_VERSION='0.50.1'
export OSV_VERSION='1.7.0'
export SYFT_VERSION='1.3.0'
export GRYPE_VERSION='0.77.1'
export BEARER_VERSION='1.43.2'

# Supporting frameworks
export FERNFLOWER_VERSION='241.15989.21'
export MUSTACHE_VERSION='3.0.5'
export NIST_MIRROR_VERSION='1.6.0'
export D3_VERSION='7.9.0'
export JQUERY_VERSION='3.7.1'
export BOOTSTRAP_VERSION='5.3.3'
export BOOTSTRAP_ICONS_VERSION='1.11.3'
export TIMELINES_CHART_VERSION='2.12.1'
export NGINX_VERSION='1.25.5'

# Name of all container images
export CONTAINER_IMAGE_NAME_FERNFLOWER="fernflower:${FERNFLOWER_VERSION}"
export CONTAINER_IMAGE_NAME_CSA="csa:${CSA_VERSION}"
export CONTAINER_IMAGE_NAME_CSA_BAGGER="csa-bagger:${CSA_BAGGER_VERSION}"
export CONTAINER_IMAGE_NAME_WINDUP="windup:${WINDUP_VERSION}"
export CONTAINER_IMAGE_NAME_WAMT="wamt:${WAMT_VERSION}"
export CONTAINER_IMAGE_NAME_OWASP_DC="owasp-dependency-check:${OWASP_DC_VERSION}"
export CONTAINER_IMAGE_NAME_SCANCODE="scancode-toolkit:${SCANCODE_VERSION}"
export CONTAINER_IMAGE_NAME_PMD="pmd:${PMD_VERSION}"
export CONTAINER_IMAGE_NAME_LINGUIST="crazymax/linguist:${LINGUIST_VERSION}"
export CONTAINER_IMAGE_NAME_CLOC="cloc:${CLOC_VERSION}"
export CONTAINER_IMAGE_NAME_FSB="findsecbugs:${FSB_VERSION}"
export CONTAINER_IMAGE_NAME_MAI="mai:${MAI_VERSION}"
export CONTAINER_IMAGE_NAME_SLSCAN="shiftleft/sast-scan:latest"
export CONTAINER_IMAGE_NAME_INSIDER="insidersec/insider:latest"
export CONTAINER_IMAGE_NAME_SYFT="anchore/syft:v${SYFT_VERSION}"
export CONTAINER_IMAGE_NAME_GRYPE="anchore/grype:v${GRYPE_VERSION}"
export CONTAINER_IMAGE_NAME_TRIVY="trivy:${TRIVY_VERSION}"
export CONTAINER_IMAGE_NAME_OSV="ghcr.io/google/osv-scanner:v${OSV_VERSION}"
export CONTAINER_IMAGE_NAME_BEARER="bearer/bearer:v${BEARER_VERSION}"

# Supporting container images
export CONTAINER_IMAGE_NAME_ASSET_DOWNLOADER="external-assets-downloader:1.0"
export CONTAINER_IMAGE_NAME_NGINX="nginx:${NGINX_VERSION}-alpine"
## .NET runtime image used to build MAI and OWASP DC container images (https://mcr.microsoft.com/v2/dotnet/runtime/tags/list)
export DONET_RUNTIME_VERSION='8.0.4-alpine3.19'
export IMG_DOTNET_RUNTIME="mcr.microsoft.com/dotnet/runtime:${DONET_RUNTIME_VERSION}"
export IMG_ECLIPSE_TEMURIN_11="eclipse-temurin:11.0.22_7-jre"
export IMG_ECLIPSE_TEMURIN_21="eclipse-temurin:21.0.2_13-jre"
export IMG_GRADLE_8_JDK_21="gradle:8.7.0-jdk21"
export IMG_MAVEN_3_JDK_21="maven:3.9.6-eclipse-temurin-21"
