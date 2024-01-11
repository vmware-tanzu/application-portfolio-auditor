#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Analyze all EAR, WAR binary applications in ${APP_DIR_IN} grouped in sub-folders using ...
#   "IBM WebSphere Application Server Migration Toolkit" - https://www.ibm.com/developerworks/library/mw-1701-was-migration/index.html
##############################################################################################################

# ----- Please adjust

#    --sourceAppServer=[jboss|liberty|libertyCore|other|tomcat|was61|was70|was80|was855|was90|weblogic]
#	Include rules for migrating from the specified source application server to the target application server. The default is was855.
#	The following options are valid:
#	* jboss - JBoss Application Server
#	* liberty - WebSphere Application Server Liberty
#	* libertyCore - WebSphere Application Server Liberty Core
#	* other - Other third-party servers
#	* tomcat - Apache Tomcat Application Server
#	* was61 - WebSphere Application Server traditional V6.1
#	* was70 - WebSphere Application Server traditional V7.0
#	* was80 - WebSphere Application Server traditional V8.0
#	* was855 - WebSphere Application Server traditional V8.5.5
#	* was90 - WebSphere Application Server traditional V9.0
#	* weblogic - WebLogic Application Server
SOURCE_APPLICATION_SERVER=jboss

#    --targetJakartaEE=[ee8|ee9|ee10]
#	Include rules for migrating to the specified target Jakarta Enterprise Edition version. The default for Liberty target application server includes the Jakarta EE rules that are applicable for the Liberty features used by the application.
#	The targetJakartaEE option cannot be used with targetJavaEE. The targetJakartaEE ee8 and ee9 options are only supported with the targetJava options ibm8, oracle8, or later. The targetJakartaEE ee10 option is only supported with targetJava options java11 and later.
#	The following options are valid:
#	* ee8  - Jakarta EE 8
#	* ee9  - Jakarta EE 9
#	* ee10 - Jakarta EE 10
TARGET_EE=ee10

#    --targetCloud=[containers|cfIBMCloud|thirdParty|vmIBMCloud]
#	Include rules for migrating to the specified target cloud runtime environment. There is no default. If you specify this option without a source or target application server, only cloud rules are included.
#	The following options are valid:
#	* containers - Containers (OpenShift, Kubernetes)
#	* cfIBMCloud - IBM Cloud Runtimes (CF PaaS)
#	* thirdParty - Third-party PaaS (CF)
#	* vmIBMCloud - Virtual machines (IBM Cloud)
TARGET_CLOUD=containers

#    --targetJava=[ibm8|java11|java17|oracle8]
#	Include rules for migrating to the specified target Java version
#	from the source Java version. The default is ibm8 for all target
#	application server options. The following options are valid:
#	* ibm8 - IBM Java 8
#	* java11 - Java 11 (LTS)
#	* java17 - Java 17 (LTS)
#	* oracle8 - Oracle Java 8
TARGET_JAVA=java17

#    --sourceJava=[ibm5|ibm6|ibm7|ibm8|java11|java17|oracle5|oracle6|oracle7|oracle8]
#	Include rules for migrating from the specified source Java version to the target Java version. The default is ibm5 for V6.1, ibm6 for V7.0 to V8.5.5, and ibm8 for the V9.0 traditional source application server options. The default is ibm8 for all other source application application server options. The following options are valid:
#	* ibm5 - IBM Java 5
#	* ibm6 - IBM Java 6
#	* ibm7 - IBM Java 7
#	* ibm8 - IBM Java 8
#	* java11 - Java 11  (LTS)
#	* java17 - Java 17  (LTS)
#	* oracle5 - Oracle Java 5
#	* oracle6 - Oracle Java 6
#	* oracle7 - Oracle Java 7
#	* oracle8 - Oracle Java 8
SOURCE_JAVA=ibm5

# ------ Do not modify
VERSION=${WAMT_VERSION}
#WAMT_JAR=${INSTALL_DIR}/wamt/binaryAppScanner.jar
STEP=$(get_step)
CONTAINER_IMAGE_NAME="wamt:${VERSION}"

APP_DIR_OUT="${REPORTS_DIR}/${STEP}__WAMT"
LOG_FILE="${APP_DIR_OUT}".log

# Analyse all applications present in the ${1} directory.
function analyze() {
	GROUP=$(basename "${1}")
	APP_FOUND="false"
	JAVA_BIN_LIST="${REPORTS_DIR}/list__${GROUP}__java-bin.txt"

	log_analysis_message "group '${GROUP}'"

	while read -r APP; do
		APP_FOUND="true"
		APP_NAME=$(basename "${APP}")
		APP_DIR=$(dirname "${APP}")
		log_analysis_message "app '${APP_NAME}'"
		ARGS=(
			"/apps/${APP_NAME}"
			--all
			--detectSharedLibraries
			--sourceAppServer="${SOURCE_APPLICATION_SERVER}"
			--targetJakartaEE="${TARGET_EE}"
			--targetCloud="${TARGET_CLOUD}"
			--sourceJava="${SOURCE_JAVA}"
			--targetJava="${TARGET_JAVA}"
			--output="/out/${GROUP}__${APP_NAME}.html"
		)
		set +e
		(time ${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm -v "${APP_DIR}:/apps:ro" -v "${APP_DIR_OUT}:/out:delegated" --name WAMT "${CONTAINER_IMAGE_NAME}" "${ARGS[@]}") >>"${LOG_FILE}" 2>&1
		set -e
	done < <(grep '.*\.[ew]ar$' "${JAVA_BIN_LIST}")

	if [[ "${APP_FOUND}" == "true" ]]; then
		log_console_success "Open this directory for the results: ${APP_DIR_OUT}"
	else
		log_console_warning "No EAR/WAR Java application found. Skipping WAMT analysis."
	fi
}

function main() {
	log_tool_info "IBM WAMT (WebSphere Application Server Migration Toolkit) v${VERSION}"
	if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME}") ]]; then
		mkdir -p "${APP_DIR_OUT}"
		for_each_group analyze
	else
		log_console_error "IBM WAMT analysis canceled. Container image unavailable: '${CONTAINER_IMAGE_NAME}'"
	fi
}

main
