#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all binary applications (EAR/WAR/JAR) in ${APP_DIR_IN} grouped in sub-folders using ...
#   "PMD" - https://pmd.github.io/
#
# "PMD" is an extensible cross-language static code analyzer finding common programming flaws.
##############################################################################################################

# ------ Feel free to adjust the used RuleSet ( https://pmd.github.io/latest/pmd_rules_java.html )
# Rulesets filtered from https://github.com/pmd/pmd/tree/master/pmd-java/src/main/resources/category/java - Not included: category/java/documentation.xml category/java/codestyle.xml category/java/design.xml
RULESETS=category/java/bestpractices.xml,category/java/errorprone.xml,category/java/multithreading.xml,category/java/performance.xml,category/java/security.xml

# ------ Do not modify
VERSION=${PMD_VERSION}
STEP=$(get_step)
APP_DIR_OUT=${REPORTS_DIR}/${STEP}__PMD
LOG_FILE="${APP_DIR_OUT}.log"
PMD_DIR_OUT="${APP_DIR_OUT}/pmd"
CPD_DIR_OUT="${APP_DIR_OUT}/cpd"
ANALYZABLE_APP_FOUND="false"

function analyze() {

	LANGUAGE=${1}
	APP_LIST=${2}

	if [[ -s "${APP_LIST}" ]]; then

		ANALYZABLE_APP_FOUND="true"

		while read -r APP; do
			APP_NAME=$(basename "${APP}")
			APP_DIR=$(dirname "${APP}")
			log_analysis_message "app '${APP_NAME}'"

			if [[ "${LANGUAGE}" == "java" ]]; then
				# Generate the quality report
				set +e
				(time ${CONTAINER_ENGINE} run --rm -v "${APP_DIR}:/app:ro" -v "${PMD_DIR_OUT}:/out:delegated" "${CONTAINER_IMAGE_NAME_PMD}" check --no-progress --no-cache -d "/app/${APP_NAME}" -f summaryhtml --rulesets "${RULESETS}" --no-fail-on-violation --report-file "/out/${APP_NAME}_pmd.html") >>"${LOG_FILE}" 2>&1
				set -e
			fi

			if [[ "${LANGUAGE}" == 'javascript' ]]; then
				LANGUAGE='ecmascript'
			fi

			# Generate the copy-paste report
			CPD_OUT=${CPD_DIR_OUT}/${APP_NAME}__cpd.xml
			set +e
			(time ${CONTAINER_ENGINE} run --rm -v "${APP_DIR}:/app:ro" "${CONTAINER_IMAGE_NAME_PMD}" cpd --minimum-tokens 100 -d "/app/${APP_NAME}" --format xml --language "${LANGUAGE}" --no-fail-on-violation --skip-lexical-errors >"${CPD_OUT}") >>"${LOG_FILE}" 2>&1
			set -e
		done <"${APP_LIST}"

	fi
}

function main() {
	log_tool_info "PMD v${VERSION}"
	if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_PMD}") ]]; then
		# Analyze all applications present in the ${APP_GROUP_DIR} directory.
		mkdir -p "${PMD_DIR_OUT}" "${CPD_DIR_OUT}"
		analyze java "${REPORTS_DIR}/00__Weave/list__java-src.txt"
		analyze python "${REPORTS_DIR}/00__Weave/list__python.txt"
		analyze javascript "${REPORTS_DIR}/00__Weave/list__js.txt"
		analyze cs "${REPORTS_DIR}/00__Weave/list__cs.txt"
		if [[ "${ANALYZABLE_APP_FOUND}" == "true" ]]; then
			log_console_success "Open this directory for the results: ${APP_DIR_OUT}"
		else
			log_console_warning "No suitable app found. Skipping PMD analysis."
		fi
	else
		log_console_error "PMD analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME_PMD}'"
	fi
}

main
