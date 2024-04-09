#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Package the generated reports if necessary to be zipped, deployed on Cloud Foundry or on Kubernetes.
#
# cf: Different descriptors are created to deploy the results on cloud-foundry.
#     In the additional created folder (named *_CF), you will find:
#     -> a 'public' directory containing the content meant to be served by an nginx instance.
#     -> a 'csa' directory with a copy of the CSA database served by a sidecar binary container.
#
# k8: Different descriptors are created to deploy the results on kubernetes.
#     In the additional created folder (named *_K8), you will find:
#     -> a 'reports' directory containing the generate report content.
#     -> a 'deploy' directory containing the descriptions to deploy reports as local container / kubernetes.
##############################################################################################################

# ----- Please adjust
# set -x
# Used nginx buildpack
#export NGINX_BUILDPACK="nginx_buildpack"
export NGINX_BUILDPACK="https://github.com/cloudfoundry/nginx-buildpack.git"
export CF_NAME_PREFIX="tanzu-app-report"

# ------ Do not modify
TEMPLATE_DIR=${DIST_DIR}/templating
TEMPLATE_DIR_CF=${TEMPLATE_DIR}/cf
TEMPLATE_DIR_K8=${TEMPLATE_DIR}/k8
MUSTACHE="${TEMPLATE_DIR}/mo_${MUSTACHE_VERSION}"
export LOG_FILE=/dev/null
export CF_APP_NAME
export K8_REPORT_NAME
export K8_REPORT_VERSION="${TOOL_VERSION}"
export ARCH="$(uname -m)"

REPORTS_DIR_CF="${REPORTS_DIR}_CF"
REPORTS_DIR_K8="${REPORTS_DIR}_K8"

function generate_cf_deployment() {
	rm -Rf "${REPORTS_DIR_CF}"
	REPORTS_DIR_CF_CSA="${REPORTS_DIR_CF}/csa"
	REPORTS_DIR_CF_PUBLIC="${REPORTS_DIR_CF}/public"

	mkdir -p "${REPORTS_DIR_CF_PUBLIC}" "${REPORTS_DIR_CF_CSA}"

	T=$(echo "${TIMESTAMP}" | tr '_' '-')
	CF_APP_NAME="${CF_NAME_PREFIX}-${T}--${APP_GROUP}"

	cp -Rfp "${REPORTS_DIR}/" "${REPORTS_DIR_CF_PUBLIC}/."

	declare MANIFEST
	# Generate a sidecar if some CSA report has been successfully generated
	if [[ -f "${REPORTS_DIR}/02__CSA/db/csa.db" ]]; then
		MANIFEST=manifest-all.yml.mo
		cp -fp "${INSTALL_DIR}/cloud-suitability-analyzer/csa-l" "${REPORTS_DIR_CF_CSA}/."
		cp -fp "${REPORTS_DIR}/02__CSA/db/csa.db" "${REPORTS_DIR_CF_CSA}/."
		rm -Rf "${REPORTS_DIR_CF_PUBLIC}/02__CSA"
		rm -Rf "${REPORTS_DIR_CF_PUBLIC}/launch_csa_ui.sh"
	else
		MANIFEST=manifest.yml.mo
	fi

	${MUSTACHE} "${TEMPLATE_DIR_CF}/cf-push.sh.mo" >"${REPORTS_DIR_CF}/cf-push.sh"
	${MUSTACHE} "${TEMPLATE_DIR_CF}/${MANIFEST}" >"${REPORTS_DIR_CF}/manifest.yml"
	cp -fp "${TEMPLATE_DIR_CF}/.profile" "${REPORTS_DIR_CF}"
	cp -fp "${TEMPLATE_DIR_CF}/buildpack.yml" "${REPORTS_DIR_CF}"
	cp -fp "${TEMPLATE_DIR_CF}/mime.types" "${REPORTS_DIR_CF}"
	cp -fp "${TEMPLATE_DIR_CF}/nginx.conf" "${REPORTS_DIR_CF}"

	chmod +x "${REPORTS_DIR_CF}/cf-push.sh"

	# Zip public directory
	pushd "${REPORTS_DIR_CF}" &>/dev/null
	set +e
	zip -r public.zip ./public &>/dev/null
	rm -Rf ./public
	set -e
	popd &>/dev/null
}

function generate_k8_deployment() {

	rm -Rf "${REPORTS_DIR_K8}"
	REPORTS_DIR_K8_DEPLOY="${REPORTS_DIR_K8}/deploy"
	REPORTS_DIR_K8_REPORTS="${REPORTS_DIR_K8}/reports"
	REPORTS_DIR_K8_PUBLIC="${REPORTS_DIR_K8}/reports/public"

	mkdir -p "${REPORTS_DIR_K8_DEPLOY}" "${REPORTS_DIR_K8_REPORTS}" "${REPORTS_DIR_K8_PUBLIC}"

	T=$(echo "${TIMESTAMP}" | tr '_' '-')
	K8_REPORT_NAME="${T}-${APP_GROUP}"

	cp -Rfp "${REPORTS_DIR}/" "${REPORTS_DIR_K8_PUBLIC}/."
	cp -Rfp "${TEMPLATE_DIR_K8}/deploy" "${REPORTS_DIR_K8}/."

	# Generate a sidecar if some CSA report has been successfully generated
	if [[ -f "${REPORTS_DIR}/02__CSA/db/csa.db" ]]; then
		# Setting up Dockerfile
		${MUSTACHE} "${REPORTS_DIR_K8_DEPLOY}/Dockerfile.csa.mo" >"${REPORTS_DIR_K8_DEPLOY}/Dockerfile"

		# Setting up CSA
		cp -fp "${TEMPLATE_DIR_K8}/deploy/container-serve-reports.sh" "${REPORTS_DIR_K8_DEPLOY}/"

		# Copy CSA binary
		${CONTAINER_ENGINE} create --name csa-dummy "${CONTAINER_IMAGE_NAME_CSA}"
		${CONTAINER_ENGINE} cp "csa-dummy:/tool/csa" "${REPORTS_DIR_K8_DEPLOY}/csa-l_${ARCH}"
		${CONTAINER_ENGINE} rm -f csa-dummy

		if [[ "${ARCH}" == "arm64" ]]; then
			${CONTAINER_ENGINE} create --name csa-dummy "${CONTAINER_IMAGE_NAME_CSA}" --platform "linux/amd64"
			${CONTAINER_ENGINE} cp "csa-dummy:/tool/csa" "${REPORTS_DIR_K8_DEPLOY}/csa-l_x86_64"
			${CONTAINER_ENGINE} rm -f csa-dummy
		fi

		# Copy CSA DB
		cp -fp "${REPORTS_DIR}/02__CSA/db/csa.db" "${REPORTS_DIR_K8_REPORTS}/"

		# Cleanup
		rm -Rf "${REPORTS_DIR_K8_PUBLIC}/02__CSA"
		rm -Rf "${REPORTS_DIR_K8_PUBLIC}/launch_csa_ui.sh"
	else
		# Setting up Dockerfile
		${MUSTACHE} "${REPORTS_DIR_K8_DEPLOY}/Dockerfile.simple.mo" >"${REPORTS_DIR_K8_DEPLOY}/Dockerfile"
	fi

	rm -f "${REPORTS_DIR_K8_DEPLOY}/Dockerfile.simple.mo" "${REPORTS_DIR_K8_DEPLOY}/Dockerfile.csa.mo"

	# Generate deployment scripts
	${MUSTACHE} "${TEMPLATE_DIR_K8}/deploy_container_local.sh.mo" >"${REPORTS_DIR_K8}/deploy_container_local.sh"
	${MUSTACHE} "${TEMPLATE_DIR_K8}/deploy_k8.sh.mo" >"${REPORTS_DIR_K8}/deploy_k8.sh"
	chmod +x "${REPORTS_DIR_K8}/deploy_k8.sh" "${REPORTS_DIR_K8}/deploy_container_local.sh"

	# Zip reports directory
	pushd "${REPORTS_DIR_K8}" &>/dev/null
	set +e
	zip -r reports.zip ./reports &>/dev/null
	rm -Rf ./reports
	set -e
	popd &>/dev/null

}

function main() {

	log_console_info "Packaging the reports - CF: ${PACKAGE_CF} - K8: ${PACKAGE_K8} - ZIP: ${PACKAGE_ZIP}"

	if [[ "${PACKAGE_CF}" == "true" ]]; then
		# Generate the Cloud Foundry deployment
		generate_cf_deployment
	elif [[ "${PACKAGE_K8}" == "true" ]]; then
		# Generate the K8 deployment
		generate_k8_deployment
	fi

	export REPORTS REPORT_DIR_NAME

	# Zipping the reports
	if [[ "${PACKAGE_ZIP}" == "true" ]]; then
		if [[ "${PACKAGE_CF}" == "true" ]]; then
			REPORTS=${REPORTS_DIR_CF}
		elif [[ "${PACKAGE_K8}" == "true" ]]; then
			REPORTS=${REPORTS_DIR_K8}
		else
			REPORTS=${REPORTS_DIR}
		fi

		REPORT_DIR_NAME=$(basename "${REPORTS}")
		pushd "${REPORTS}/.." &>/dev/null
		set +e
		rm -f "${REPORT_DIR_NAME}.zip"
		zip -r "${REPORT_DIR_NAME}.zip" "${REPORT_DIR_NAME}" &>/dev/null
		#rm -Rf "${REPORTS}"
		set -e
		popd &>/dev/null
	fi

	# Logging
	if [[ "${PACKAGE_ZIP}" == "true" ]]; then
		FORMAT=''
		if [[ "${PACKAGE_CF}" == "true" ]]; then
			FORMAT=' as CF-deployable (cf-push.sh)'
		elif [[ "${PACKAGE_K8}" == "true" ]]; then
			FORMAT=' as K8 deployment'
		fi
		log_console_success "Report successfully zipped${FORMAT}: '${REPORTS}.zip'"
	else
		if [[ "${PACKAGE_CF}" == "true" ]]; then
			log_console_success "CF deployment succesfully created. Deploy by executing: 'cd ${REPORTS_DIR_CF}; ./cf-push.sh'"
		elif [[ "${PACKAGE_K8}" == "true" ]]; then
			log_console_success "K8 deployment succesfully created. Run by executing either of:"
			log_console_success "  a) Local deployment 'cd ${REPORTS_DIR_K8}; ./deploy_container_local.sh' (http://localhost)"
			log_console_success "  b) Kubernetes deployment 'cd ${REPORTS_DIR_K8}; ./deploy_k8.sh' (http://localhost:30001)"
		fi
	fi

	if [[ "${PACKAGE_CF}" == "true" ]]; then
		log_console_info "Depending on your running TAS instance, you might have to change the nginx buildpack in use (manifest.yml) to 'https://github.com/cloudfoundry/nginx-buildpack.git' or to 'nginx_buildpack'"
	fi
}

main
