#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all binary applications (EAR/WAR/JAR) in ${APP_DIR_IN} grouped in sub-folders using ...
#	"Cloud Suitability Analyzer" - https://github.com/vmware-tanzu/cloud-suitability-analyzer
##############################################################################################################

# ----- Please adjust
CSA_DEFAULT_BUSINESS_VALUE=5

# ------ Do not modify
STEP=$(get_step)

VERSION=${CSA_VERSION}
APP_DIR_OUT=${REPORTS_DIR}/${STEP}__CSA
DB_DIR_OUT=${REPORTS_DIR}/${STEP}__CSA/db
LOG_FILE=${APP_DIR_OUT}.log
LAUNCH_UI_SCRIPT=${APP_DIR_OUT}/../launch_csa_ui.sh

# Analyze all applications present in the ${APP_GROUP_DIR} directory.
function analyze() {
	declare APP_SUB_DIR_IN TYPE EXT
	# Analyze decompiled apps if existing
	if [ -d "${APP_GROUP_SRC_DIR}" ]; then
		APP_SUB_DIR_IN="${APP_GROUP_SRC_DIR}"
		TYPE="d"
		EXT="/"
	else
		# FIXME: Does not really work by providing apps directly (incorrect results)
		APP_SUB_DIR_IN="${APP_GROUP_DIR}"
		TYPE="f"
		EXT=""
	fi

	APP_CONF="${APP_DIR_OUT}/conf-${APP_GROUP}.yml"

	# Build the configuration file (${APP_CONF})
	echo "runName: ${APP_GROUP}" >"${APP_CONF}"
	echo "applications:" >>"${APP_CONF}"

	while read -r APP; do
		APP_NAME=$(echo "${APP}" | rev | cut -d'/' -f1 | rev)
		APP_SHORT="/apps/${APP##$APP_GROUP_DIR}"
		cat >>"${APP_CONF}" <<EOF
- name: ${APP_NAME}
  path: ${APP_SHORT}${EXT}
  business-value: ${CSA_DEFAULT_BUSINESS_VALUE}
EOF
		cat >>"${APP_CONF}" <<'EOF'
  scoring-model: default
  dir-exclude-regex: ^([.].*|target|bin|test|node_modules|eclipse|out|vendors)$
  include-file-regex: .*
  exclude-file-regex: ^(.*[.](exe|png|tiff|tif|gif|jpg|jpeg|bmp|dmg|mpeg|class)|[.].*|csa-config[.](yaml|yml|json))$
EOF
	done < <(find "${APP_SUB_DIR_IN}" -maxdepth 1 -mindepth 1 -type "${TYPE}")

	cat >>"${APP_CONF}" <<'EOF'
scoring-model: default
rule-include-tags: ""
rule-exclude-tags: ""
dir-exclude-regex: ^([.].*|target|bin|test|node_modules|eclipse|out|vendors)$
include-file-regex: .*
exclude-file-regex: ^(.*[.](exe|png|tiff|tif|gif|jpg|jpeg|bmp|dmg|mpeg|class)|[.].*|csa-config[.](yaml|yml|json))$
EOF

	log_console_info "Configuration completed: '${APP_CONF}'"

	# Execute the analysis
	log_console_step "Cloud Suitability Analyzer execution ..."

	set +e
	(time ${CONTAINER_ENGINE} run --rm \
		-v "${APP_DIR_OUT}:/out:delegated" -v "${DB_DIR_OUT}:/db" -v "${APP_GROUP_DIR}:/apps" \
		"${CONTAINER_IMAGE_NAME_CSA}" \
		analyze --database-dir="/db" --config-file="/out/conf-${APP_GROUP}.yml" --output-dir="/out" --display-rule-metrics --display-ignored-files --export=csv,html --export-dir="/out/export" --export-file-name="export") >>"${LOG_FILE}" 2>&1
	set -e
}

function create_launch_script() {
	cat >"${LAUNCH_UI_SCRIPT}" <<EOF
#!/usr/bin/env bash
echo "To access your CSA report, open http://localhost:3001"
${CONTAINER_ENGINE} run -p 3001:3001 --rm -v "./${STEP}__CSA/db:/db" "${CONTAINER_IMAGE_NAME_CSA}" ui --database-dir=/db --port=3001
EOF
	chmod +x "${LAUNCH_UI_SCRIPT}"
}

function main() {

	log_tool_info "Cloud Suitability Analyzer (CSA) v${VERSION}"
	if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_CSA}") ]]; then
		mkdir -p "${DB_DIR_OUT}"
		analyze
		create_launch_script
		log_console_success "CSA analysis completed."
		log_console_info " Log file: '${LOG_FILE}'"
		log_console_info " To see the results start the UI with '${LAUNCH_UI_SCRIPT}' and open http://localhost:3001"
	else
		log_console_error "CSA result extraction canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_CSA}'"
	fi

}

main
