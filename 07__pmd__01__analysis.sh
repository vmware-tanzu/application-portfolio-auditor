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
RULESETS=category/java/security.xml,category/java/design.xml/AbstractClassWithoutAnyMethod,category/java/design.xml/AvoidThrowingNullPointerException,category/java/design.xml/AvoidThrowingRawExceptionTypes,category/java/design.xml/ClassWithOnlyPrivateConstructorsShouldBeFinal,category/java/errorprone.xml/ConstructorCallsOverridableMethod,category/java/errorprone.xml/EqualsNull,category/java/errorprone.xml/ReturnEmptyArrayRatherThanNull,category/java/multithreading.xml/AvoidUsingVolatile,category/java/multithreading.xml/DoubleCheckedLocking,category/java/performance.xml/AvoidFileStream,rulesets/GDS/SecureCoding.xml

# ------ Do not modify
VERSION=${PMD_VERSION}
PMD_RUN=${INSTALL_DIR}/pmd-bin-${VERSION}/bin/run.sh
STEP=$(get_step)
APP_DIR_OUT=${REPORTS_DIR}/${STEP}__PMD
LOG_FILE=${APP_DIR_OUT}.log
PMD_DIR_OUT=${APP_DIR_OUT}/pmd
CPD_DIR_OUT=${APP_DIR_OUT}/cpd
ANALYZABLE_APP_FOUND="false"

function analyze() {

	LANGUAGE=${1}
	APP_LIST=${2}
	GROUP=${3}

	if [[ -s "${APP_LIST}" ]]; then

		ANALYZABLE_APP_FOUND="true"

		while read -r APP; do
			APP_NAME=$(basename "${APP}")
			log_analysis_message "app '${APP_NAME}'"

			if [[ "${LANGUAGE}" == "java" ]]; then
				PMD_OUT=${PMD_DIR_OUT}/${GROUP}__${APP_NAME}_pmd.html
				# Alternative formats: csv summaryhtml
				set +e
				(time "${PMD_RUN}" pmd --dir "${APP}" -f summaryhtml --rulesets "${RULESETS}" --fail-on-violation false --short-names >"${PMD_OUT}") >>"${LOG_FILE}" 2>&1
				set -e
			fi

			CPD_OUT=${CPD_DIR_OUT}/${GROUP}__${APP_NAME}__cpd.xml
			# Alternative formats: text xml csv csv_with_linecount_per_file vs
			set +e
			(time "${PMD_RUN}" cpd --minimum-tokens 100 --files "${APP}" --format xml --language "${LANGUAGE}" --fail-on-violation false --skip-lexical-errors >"${CPD_OUT}") >>"${LOG_FILE}" 2>&1
			set -e
		done <"${APP_LIST}"

	fi
}

# Analyse all applications present in the ${1} directory.
function analyze_group() {
	GROUP=$(basename "${1}")
	log_analysis_message "group '${GROUP}'"

	analyze java "${REPORTS_DIR}/list__${GROUP}__java-src.txt" "${GROUP}"
	analyze python "${REPORTS_DIR}/list__${GROUP}__python.txt" "${GROUP}"
	analyze javascript "${REPORTS_DIR}/list__${GROUP}__js.txt" "${GROUP}"
	analyze cs "${REPORTS_DIR}/list__${GROUP}__cs.txt" "${GROUP}"

	if [[ "${ANALYZABLE_APP_FOUND}" == "true" ]]; then
		log_console_success "Open this directory for the results: ${APP_DIR_OUT}"
	else
		log_console_warning "No suitable app found. Skipping PMD analysis."
	fi

}

function main() {
	log_tool_info "PMD v${VERSION}"
	mkdir -p "${PMD_DIR_OUT}" "${CPD_DIR_OUT}"
	for_each_group analyze_group
}

main
