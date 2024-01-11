#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

# ============================================================================================================
# Build and run the generated report as a container image.
# ============================================================================================================

VERSION="{{K8_REPORT_VERSION}}"
REPORT_NAME="{{K8_REPORT_NAME}}"
IMG_NAME="audit-report-${REPORT_NAME}-img:${VERSION}"

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

# Build container image
DOCKER_BUILDKIT=1 docker build -f "${SCRIPT_DIR}/deploy/Dockerfile" -t "${IMG_NAME}" .

# Run container image
docker run --rm -it --name "audit-report-${REPORT_NAME}" -p 80:80 "${IMG_NAME}"
