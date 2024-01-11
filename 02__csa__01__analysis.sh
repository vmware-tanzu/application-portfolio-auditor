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
CSA_DIR=${INSTALL_DIR}/cloud-suitability-analyzer
CSA=${CSA_DIR}/csa-l
if [ "${IS_MAC}" == "true" ]; then
	CSA=${CSA_DIR}/csa
fi
CONF_DIR="${CURRENT_DIR}/conf/CSA"
DEFAULT_RULES_DIR="${CONF_DIR}/default-rules"
CUSTOM_RULES_DIR="${CONF_DIR}/custom-rules"
TMP_RULES_DIR="${CONF_DIR}/tmp-rules"
DEFAULT_BINS_FILE="${CONF_DIR}/default-bins.yaml"
CUSTOM_BINS_FILE="${CONF_DIR}/custom-bins.yaml"
TMP_BINS_FILE="${CONF_DIR}/tmp-bins.yaml"
VERSION=${CSA_VERSION}
APP_DIR_OUT=${REPORTS_DIR}/${STEP}__CSA
LOG_FILE=${APP_DIR_OUT}.log
LAUNCH_UI_SCRIPT=${APP_DIR_OUT}/../launch_csa_ui.sh

# Analyse all applications present in the ${1} directory.
function analyze() {

	SUB_DIR_NAME=$(basename "${1}")
	log_analysis_message "group '${SUB_DIR_NAME}'"

	declare APP_SUB_DIR_IN TYPE EXT
	# Analyze decompiled apps if existing
	if [ -d "${1}/src" ]; then
		APP_SUB_DIR_IN="${1}/src"
		TYPE="d"
		EXT="/"
	else
		## DOES NOT REALLY WORKS BY PROVIDING APPS DIRECTLY (WRONG GENERATED RESULTS)
		APP_SUB_DIR_IN="${1}"
		TYPE="f"
		EXT=""
	fi

	APP_CONF="${APP_DIR_OUT}/conf-${SUB_DIR_NAME}.yml"

	# Build the configuration file (${APP_CONF})
	echo "runName: ${SUB_DIR_NAME}" >"${APP_CONF}"
	echo "applications:" >>"${APP_CONF}"

	while read -r APP; do
		APP_NAME=$(echo "${APP}" | rev | cut -d'/' -f1 | rev)
		cat >>"${APP_CONF}" <<EOF
- name: ${APP_NAME}
  path: ${APP}${EXT}
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

	# Executes the analysis
	log_console_step "Cloud Suitability Analyzer execution ..."

	set +e
	#(time ${CSA} analyze --database-dir=${APP_DIR_OUT} --config-file=${APP_CONF} --output-dir=${APP_DIR_OUT} --analyze-archives --db-name=appfoundry) >> ${LOG_FILE} 2>&1
	(time ${CSA} analyze --database-dir="${APP_DIR_OUT}" --config-file="${APP_CONF}" --output-dir="${APP_DIR_OUT}" --display-rule-metrics --display-ignored-files --rules-dir="${TMP_RULES_DIR}") >>"${LOG_FILE}" 2>&1
	set -e

}

function import_bins() {
	if [[ ! -f "${DEFAULT_BINS_FILE}" ]]; then
		log_console_step "Export Cloud Suitability Analyzer Default Bins"
		"${CSA}" bins export --database-dir="${APP_DIR_OUT}" --output-dir="${CONF_DIR}" >>"${LOG_FILE}" 2>&1 || true
		mv "${CONF_DIR}"/bins.yaml "${DEFAULT_BINS_FILE}"
	fi

	if [[ ! -f "${CUSTOM_BINS_FILE}" ]]; then
		touch "${CUSTOM_BINS_FILE}"
	fi

	rm -f "${TMP_BINS_FILE}"
	touch "${TMP_BINS_FILE}"

	{
		cat "${DEFAULT_BINS_FILE}"
		echo "---"
		cat "${CUSTOM_BINS_FILE}"
	} >>"${TMP_BINS_FILE}"

	log_console_step "Import Cloud Suitability Analyzer Bins"
	"${CSA}" bins import --database-dir="${APP_DIR_OUT}" "${TMP_BINS_FILE}" >>"${LOG_FILE}" 2>&1 || true
}

function count_rules() {
	find "${1}" -maxdepth 1 -mindepth 1 -name "*.yaml" -type f | wc -l
}

function import_rules() {
	if [[ ! -d "${DEFAULT_RULES_DIR}" ]]; then
		mkdir "${DEFAULT_RULES_DIR}"
	fi

	if [[ ! -d "${CUSTOM_RULES_DIR}" ]]; then
		mkdir "${CUSTOM_RULES_DIR}"
	fi

	COUNT_DEFAULT_RULES=$(count_rules "${DEFAULT_RULES_DIR}")
	if ((COUNT_DEFAULT_RULES == 0)); then
		log_console_step "Export Cloud Suitability Analyzer Default Rules"
		"${CSA}" rules export --database-dir="${APP_DIR_OUT}" --rules-dir="${DEFAULT_RULES_DIR}" >>"${LOG_FILE}" 2>&1 || true
		COUNT_DEFAULT_RULES=$(count_rules "${DEFAULT_RULES_DIR}")
	fi

	rm -rf "${TMP_RULES_DIR}"
	mkdir "${TMP_RULES_DIR}"

	if ((COUNT_DEFAULT_RULES > 0)); then
		cp -af "${DEFAULT_RULES_DIR}"/*.yaml "${TMP_RULES_DIR}"
	fi

	COUNT_CUSTOM_RULES=$(count_rules "${CUSTOM_RULES_DIR}")
	if ((COUNT_CUSTOM_RULES > 0)); then
		cp -af "${CUSTOM_RULES_DIR}"/*.yaml "${TMP_RULES_DIR}"
	fi

	log_console_step "Import Cloud Suitability Analyzer Rules"
	"${CSA}" rules import --database-dir="${APP_DIR_OUT}" --rules-dir="${TMP_RULES_DIR}" >>"${LOG_FILE}" 2>&1 || true
}

function main() {

	log_tool_info "Cloud Suitability Analyzer (CSA) v${VERSION}"

	mkdir -p "${APP_DIR_OUT}"

	import_bins
	import_rules

	for_each_group analyze

	rm -rf "${TMP_RULES_DIR}"
	rm -rf "${TMP_BINS_FILE}"

	# Generate launch script
	cat >"${LAUNCH_UI_SCRIPT}" <<EOF
#!/usr/bin/env bash
# Replace with a pointer to your local CSA instance or set the CSA_DIR environment variable
if [ -z "\${CSA_DIR}" ] ; then
	CSA_DIR="../../bin/cloud-suitability-analyzer"
fi
if [[ ! -d "\${CSA_DIR}" ]]; then
	echo "[ERROR] Cloud Suitability Analyzer directory not found: '\${CSA_DIR}'. Please set the CSA_DIR environment variable."
	exit 1
fi
if [[ "\$(uname -s)" == "Darwin" ]]; then
	CSA=\${CSA_DIR}/csa
else
	CSA=\${CSA_DIR}/csa-l
fi
\${CSA} ui --database-dir=./${STEP}__CSA
EOF
	chmod +x "${LAUNCH_UI_SCRIPT}"

	# Instructions
	log_console_success "CSA analysis completed."
	log_console_info " Log file: '${LOG_FILE}'"
	log_console_info " To see the results ... "
	log_console_info "    1) execute: ${CSA} ui --database-dir=${APP_DIR_OUT}"
	log_console_info "    2) and open http://localhost:3001"

}

main
