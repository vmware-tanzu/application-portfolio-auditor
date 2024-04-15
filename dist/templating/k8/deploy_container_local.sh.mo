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

# Delete existing local image
{{CONTAINER_ENGINE}} images -a | grep "audit-report-${REPORT_NAME}-img" | awk '{print $3}' | xargs -r "{{CONTAINER_ENGINE}}" rmi --force

# Build local container image
DOCKER_BUILDKIT=1 {{CONTAINER_ENGINE}} buildx build --build-arg ARCH="$(uname -m)" -f "${SCRIPT_DIR}/deploy/Dockerfile" -t "${IMG_NAME}" .

# Run container image
{{CONTAINER_ENGINE}} run --rm -it --name "audit-report-${REPORT_NAME}" -p 80:8080 "${IMG_NAME}"
