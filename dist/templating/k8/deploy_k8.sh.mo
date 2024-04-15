#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

# ============================================================================================================
#
# Deploy the generated report to a K8 cluster.
#
# Optional parameters you can pass to this script:
# - REPORT_TAG: Tag used to name the image and many K8 objects.
# - VERSION: Version of the container image.
# - TARGET_HOST: Hostname of the application deployed on K8s.
# - HARBOR_PROJECT: Name of the harbor project
#
# Additionally, you can pass one Kubernetes command to override the default "apply" command.
#
# Examples:
# - ./deploy_k8.sh
# - TARGET_HOST=audit-report.acme.com REPORT_TAG=acme ./deploy_k8.sh delete
#
# ============================================================================================================

declare REPORT_TAG VERSION TARGET_HOST HARBOR_PROJECT TEMPLATE

if [ -z "${REPORT_TAG}" ]; then
	REPORT_TAG="{{K8_REPORT_NAME}}"
fi

if [ -z "${VERSION}" ]; then
	VERSION="{{K8_REPORT_VERSION}}"
fi

IMG_NAME="audit-report-${REPORT_TAG}-img:${VERSION}"
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

if [ -z "${K8_COMMAND}" ]; then
	K8_COMMAND="apply"
fi

# Build container image
DOCKER_BUILDKIT=1 {{CONTAINER_ENGINE}} buildx build --build-arg ARCH="x86_64" -f "${SCRIPT_DIR}/deploy/Dockerfile" -t "${IMG_NAME}" --platform=linux/amd64 .

# Tag and push image to a harbor registry
if [ -n "${HARBOR_PROJECT}" ]; then
	{{CONTAINER_ENGINE}} tag "${IMG_NAME}" "${HARBOR_PROJECT}/${IMG_NAME}"
	{{CONTAINER_ENGINE}} push "${HARBOR_PROJECT}/${IMG_NAME}"
	IMG_NAME="${HARBOR_PROJECT}/${IMG_NAME}"
fi

# Select right K8 template
if [ -z "${TARGET_HOST}" ]; then
	TEMPLATE="k8-deployment-template.yaml"
else
	TEMPLATE="k8-deployment-with-host-template.yaml"
fi
echo "Using template: ${TEMPLATE}"

export REPORT_TAG TARGET_HOST IMG_NAME
# Apply deployment template and deploy to K8s
echo "TEMPLATE:${TEMPLATE} - REPORT_TAG:${REPORT_TAG} - TARGET_HOST:${TARGET_HOST}"
envsubst "\$REPORT_TAG \$TARGET_HOST \$TARGET_HOST_NAMESPACE \$TARGET_HOST_INGRESS_CLASS \$TARGET_HOST_SECRET_NAME \$IMG_NAME" <"${SCRIPT_DIR}/deploy/${TEMPLATE}" | kubectl apply -f -

echo "To check on the deployment just execute:"
echo "   kubectl get pods"
if [ -z "${TARGET_HOST}" ]; then
	echo "   curl http://localhost:30001"
else
	echo "   curl https://${TARGET_HOST}"
fi
