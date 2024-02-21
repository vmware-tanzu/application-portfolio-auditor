#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Extract key results from the reports generated by "Archeo"
##############################################################################################################

# ----- Please adjust

# ------ Do not modify
export VERSION=${TOOL_VERSION}
STEP=$(get_step)
SEPARATOR=","

TODAY="$(date +%Y-%m-%d)"
CONF_DIR="${CURRENT_DIR}/conf/archeo"

declare -A PROJECT_ID_MAP=(
	["micrometer-io"]="Micrometer"
	["spring-amqp"]="Spring AMQP"
	["spring-authorization-server"]="Spring Authorization Server"
	["spring-batch"]="Spring Batch"
	["spring-boot"]="Spring Boot"
	#["spring-cli"]="Spring CLI" - page does not exist
	#["spring-cloud"]="Spring Cloud" - page does not exist
	#["spring-cloud-alibaba"]="Spring Cloud Alibaba" - page does not exist
	["spring-cloud-app-broker"]="Spring Cloud App Broker"
	#["spring-cloud-aws"]="Spring Cloud AWS"
	#["spring-cloud-azure"]="Spring Cloud Azure"
	["spring-cloud-bus"]="Spring Cloud Bus"
	["spring-cloud-circuitbreaker"]="Spring Cloud Circuit Breaker"
	["spring-cloud-cli"]="Spring Cloud CLI"
	#["spring-cloud-cloudfoundry-service-broker"]="Spring Cloud Cloud Foundry Service Broker" - page does not exist
	["spring-cloud-commons"]="Spring Cloud Commons"
	["spring-cloud-config"]="Spring Cloud Config"
	["spring-cloud-consul"]="Spring Cloud Consul"
	["spring-cloud-contract"]="Spring Cloud Contract"
	["spring-cloud-dataflow"]="Spring Cloud Data Flow"
	["spring-cloud-function"]="Spring Cloud Function"
	["spring-cloud-gateway"]="Spring Cloud Gateway"
	#["spring-cloud-gcp"]="Spring Cloud GCP" - page does not exist
	["spring-cloud-kubernetes"]="Spring Cloud Kubernetes"
	["spring-cloud-netflix"]="Spring Cloud Netflix"
	["spring-cloud-open-service-broker"]="Spring Cloud Open Service Broker"
	["spring-cloud-openfeign"]="Spring Cloud OpenFeign"
	["spring-cloud-security"]="Spring Cloud Security"
	["spring-cloud-skipper"]="Spring Cloud Skipper"
	["spring-cloud-sleuth"]="Spring Cloud Sleuth"
	["spring-cloud-stream"]="Spring Cloud Stream"
	["spring-cloud-stream-applications"]="Spring Cloud Stream Applications"
	["spring-cloud-task"]="Spring Cloud Task"
	["spring-cloud-vault"]="Spring Cloud Vault"
	["spring-cloud-zookeeper"]="Spring Cloud Zookeeper"
	["spring-credhub"]="Spring CredHub"
	["spring-data"]="Spring Data"
	["spring-data-cassandra"]="Spring Data Cassandra"
	#["spring-data-couchbase"]="Spring Data Couchbase" - page does not exist
	#["spring-data-elasticsearch"]="Spring Data Elasticsearch"
	["spring-data-envers"]="Spring Data Envers"
	["spring-data-gemfire"]="Spring Data Gemfire"
	["spring-data-geode"]="Spring Data Geode"
	["spring-data-jdbc"]="Spring Data JDBC"
	["spring-data-jpa"]="Spring Data JPA"
	["spring-data-ldap"]="Spring Data LDAP"
	["spring-data-mongodb"]="Spring Data MongoDB"
	#["spring-data-neo4j"]="Spring Data Neo4J"
	["spring-data-r2dbc"]="Spring Data R2DBC"
	["spring-data-redis"]="Spring Data Redis"
	["spring-data-rest"]="Spring Data REST"
	#["spring-flo"]="Spring Flo" - page does not exist
	["spring-framework"]="Spring Framework"
	["spring-graphql"]="Spring for GraphQL"
	["spring-hateoas"]="Spring HATEOS"
	["spring-integration"]="Spring Integration"
	["spring-kafka"]="Spring Kafka"
	["spring-ldap"]="Spring LDAP"
	#["spring-modulith"]="Spring Modulith" - page does not exist
	["spring-pulsar"]="Spring for Apache Pulsar"
	["spring-restdocs"]="Spring REST Docs"
	["spring-security"]="Spring Security"
	["spring-security-kerberos"]="Spring Security Kerberos"
	["spring-session"]="Spring Session"
	["spring-session-data-geode"]="Spring Session Data Geode"
	["spring-shell"]="Spring Shell"
	["spring-statemachine"]="Spring State Machine"
	["spring-vault"]="Spring Vault"
	["spring-webflow"]="Spring Web Flow"
	["spring-ws"]="Spring Web Services"
)

function log_finding() {
	echo "${2}${SEPARATOR}${3}${SEPARATOR}${4}${SEPARATOR}${5}${SEPARATOR}\"${6}\"" >>"${1}"
}

function check_support() {
	local BRANCH COMMERCIAL_ENFORCED_END COMMERCIAL_POLICY_END CSV_FILE DESCRIPTION E_VERSION E_VERSION_FULL E_VERSION_SHORT LIBRARY LINKED_PROJECT OSS_ENFORCED_END OSS_POLICY_END QUERY QUERY_FILTER SEVERITY PROJECT_ID SUPPORT_END_COMMERCIAL SUPPORT_END_OSS SUPPORT_INFO_FILE

	PROJECT_ID="$1"
	CSV_FILE="$2"
	LIBRARY="$3"
	E_VERSION_SHORT="$4"
	E_VERSION_FULL="$5"

	SUPPORT_INFO_FILE="${CONF_DIR}/${PROJECT_ID}__support-data.json"

	QUERY_FILTER=' | [.branch, if .commercialPolicyEnd == "" then "_" else .commercialPolicyEnd end, if .commercialEnforcedEnd == "" then "_" else .commercialEnforcedEnd end, if .ossPolicyEnd == "" then "_" else .ossPolicyEnd end, if .ossEnforcedEnd == "" then "_" else .ossEnforcedEnd end] | @tsv'
	QUERY='.[] | select(.branch | startswith("'${E_VERSION_SHORT}'"))'
	read -r BRANCH COMMERCIAL_POLICY_END COMMERCIAL_ENFORCED_END OSS_POLICY_END OSS_ENFORCED_END <<<"$(jq -r "${QUERY}${QUERY_FILTER}" "${SUPPORT_INFO_FILE}")"

	if [[ -n "${OSS_ENFORCED_END:-}" && "${OSS_ENFORCED_END}" != "_" ]]; then
		SUPPORT_END_OSS="${OSS_ENFORCED_END}"
	else
		SUPPORT_END_OSS="${OSS_POLICY_END#_}"
	fi

	if [[ -n "${COMMERCIAL_ENFORCED_END:-}" && "${COMMERCIAL_ENFORCED_END}" != "_" ]]; then
		SUPPORT_END_COMMERCIAL="${COMMERCIAL_ENFORCED_END}"
	else
		SUPPORT_END_COMMERCIAL="${COMMERCIAL_POLICY_END#_}"
	fi

	#log_console_info "> PROJECT_ID: ${PROJECT_ID} ${E_VERSION_SHORT} - SUPPORT_END_OSS: $SUPPORT_END_OSS & SUPPORT_END_COMMERCIAL: $SUPPORT_END_COMMERCIAL"
	#log_console_info ">>>> COMMERCIAL_POLICY_END: $COMMERCIAL_POLICY_END - COMMERCIAL_ENFORCED_END: $COMMERCIAL_ENFORCED_END - OSS_POLICY_END: $OSS_POLICY_END - OSS_ENFORCED_END: $OSS_ENFORCED_END"

	if [[ "${PROJECT_ID}" == "spring"* ]]; then
		URL="https://spring.io/projects/${PROJECT_ID}#support"
	else
		URL="https://micrometer.io/support/"
	fi
	LINKED_PROJECT="<a href='${URL}' rel='noreferrer' target='_blank'>${PROJECT_ID_MAP[$PROJECT_ID]} support</a>"

	if [[ -n "${SUPPORT_END_OSS:-}" ]]; then
		if [[ "${TODAY}" > "${SUPPORT_END_OSS}" ]]; then
			if [[ "${TODAY}" > "${SUPPORT_END_COMMERCIAL}" ]]; then
				# OSS and Commercial supports expired
				DESCRIPTION="${LINKED_PROJECT} ended on ${SUPPORT_END_OSS} (OSS) and ${SUPPORT_END_COMMERCIAL} (Commercial) for ${BRANCH}"
				SEVERITY='Critical'
			else
				# OSS support expired, Commercial available.
				DESCRIPTION="${LINKED_PROJECT} ended on ${SUPPORT_END_OSS} (OSS) and available till ${SUPPORT_END_COMMERCIAL} (Commercial) for ${BRANCH}"
				SEVERITY='High'
			fi
		else
			# Add a warning if the support ends in less than one year
			ONE_YEAR_FROM_TODAY="$(($(date +%Y) + 1))-$(date +%m-%d)"
			DESCRIPTION="${LINKED_PROJECT} will end on ${SUPPORT_END_OSS} (OSS) or ${SUPPORT_END_COMMERCIAL} (Commercial) for ${BRANCH} "
			if [[ "${ONE_YEAR_FROM_TODAY}" > "${SUPPORT_END_OSS}" ]]; then
				SEVERITY='Medium'
			else
				SEVERITY='Info'
			fi
		fi
	else
		# Search the lower supported OSS version. Note: 'sort_by' filters the minimum supported OSS version
		local EXTENDED_QUERY='([ .[] | select(.ossPolicyEnd > "'${TODAY}'") ] | sort_by(.branch)[0])'
		read -r BRANCH COMMERCIAL_POLICY_END COMMERCIAL_ENFORCED_END OSS_POLICY_END OSS_ENFORCED_END <<<"$(jq -r "${EXTENDED_QUERY}${QUERY_FILTER}" "${SUPPORT_INFO_FILE}")"
		DESCRIPTION="${LINKED_PROJECT} OSS expired (< ${BRANCH})"
		SEVERITY='Critical'
	fi

	if [[ -n "${SEVERITY:-}" ]]; then
		log_finding "${CSV_FILE}" "${LIBRARY}" "${E_VERSION_FULL}" "Supportability" "${SEVERITY}" "${DESCRIPTION}"
	fi
}

function generate_csv() {
	APP_DIR_INCOMING=${1}
	GROUP=$(basename "${APP_DIR_INCOMING}")

	APP_DIR_OUT="${REPORTS_DIR}/${STEP}__Archeo"
	RESULT_FILE="${APP_DIR_OUT}/_results__quality__archeo.csv"

	if [[ ! -d "${APP_DIR_OUT}" ]]; then
		LOG_FILE=/dev/null
		log_console_error "OSV result directory does not exist: ${APP_DIR_OUT}"
		exit
	fi

	export LOG_FILE="${REPORTS_DIR}/${STEP}__Archeo.log"
	log_extract_message "group '${GROUP}'"

	rm -f "${RESULT_FILE}"
	echo "Applications${SEPARATOR}Archeo Findings" >>"${RESULT_FILE}"

	while read -r APP; do
		APP_NAME="$(basename "${APP}")"
		log_extract_message "app '${APP_NAME}'"
		ARCHEO_OUTPUT="${APP_DIR_OUT}/${APP_NAME}_archeo.txt"
		ARCHEO_APP_CSV="${APP_DIR_OUT}/${APP_NAME}_archeo.csv"

		if [[ -f "${ARCHEO_OUTPUT}" ]]; then
			log_finding "${ARCHEO_APP_CSV}" "Library" "Version" "Category" "Severity" "Description"

			###### 1. Generate findings for one application
			while read -r ENTRY; do

				local E_GROUP E_PACKAGE E_VERSION_FULL E_VERSION E_VERSION_SHORT LIB
				# e.g. 'maven'
				#E_TYPE=$(echo "${ENTRY}" | cut -d '/' -f1 | cut -d ':' -f2)

				# e.g. 'org.springframework'
				E_GROUP=$(echo "${ENTRY}" | cut -d '/' -f2)

				# e.g. 'spring-aop'
				E_PACKAGE=$(echo "${ENTRY}" | cut -d '/' -f3 | cut -d '@' -f1)

				E_VERSION_FULL=''
				E_VERSION=''
				E_VERSION_SHORT=''
				# e.g. '5.1.9.RELEASE'
				if [[ "${ENTRY}" == *'@'* ]]; then
					E_VERSION_FULL=$(echo "${ENTRY}" | cut -d '@' -f2)
					if [[ -n "${E_VERSION_FULL:-}" ]]; then
						# e.g. '5.1.9'
						E_VERSION=$(echo "${E_VERSION_FULL}" | tr -d '[:alpha:]' | tr -d '-' | sed 's/\.$//')
						if [[ -n "${E_VERSION:-}" ]]; then
							E_VERSION_SHORT=$(echo "${E_VERSION}" | awk -F '.' '{printf "%s.%s", $1, $2}')
						fi
					fi
				fi

				# e.g. 'org.springframework:spring-aop'
				LIB="${E_GROUP}:${E_PACKAGE}"

				####### Unsupported Libraries
				DETECTED_PROJECT=''
				if [[ -n "${E_VERSION_SHORT:-}" ]]; then
					if [[ "${E_GROUP}" == "io.micrometer" ]]; then
						DETECTED_PROJECT="micrometer-io"
					elif [[ "${E_GROUP}" == "org.springframework"* ]]; then
						# Check support for Spring Framework (https://spring.io/projects/spring-framework#support)
						if [[ "${E_GROUP}" == "org.springframework" ]]; then
							DETECTED_PROJECT='spring-framework'

						# Check support for Spring Boot (https://spring.io/projects/spring-boot#support) - Alternatives: https://endoflife.date/spring-boot / https://endoflife.date/api/spring-boot.json
						elif [[ "${E_GROUP}" == "org.springframework.boot" ]]; then
							DETECTED_PROJECT='spring-boot'

						# Check support for Spring Session (https://spring.io/projects/spring-session#support)
						elif [[ "${E_GROUP}" == "org.springframework.session"* ]]; then
							DETECTED_PROJECT='spring-session'

						# Check support for Spring Data (https://spring.io/projects/spring-data#support)
						elif [[ "${E_GROUP}" == "org.springframework.data"* ]]; then
							if [[ "${LIB}" == *"cassandra"* ]]; then
								DETECTED_PROJECT='spring-data-cassandra'
							elif [[ "${LIB}" == *"envers"* ]]; then
								DETECTED_PROJECT='spring-data-envers'
							elif [[ "${LIB}" == *"gemfire"* ]]; then
								DETECTED_PROJECT='spring-data-gemfire'
							elif [[ "${LIB}" == *"geode"* ]]; then
								DETECTED_PROJECT='spring-data-geode'
							elif [[ "${LIB}" == *"jdbc"* ]]; then
								DETECTED_PROJECT='spring-data-jdbc'
							elif [[ "${LIB}" == *"jpa"* ]]; then
								DETECTED_PROJECT='spring-data-jpa'
							elif [[ "${LIB}" == *"ldap"* ]]; then
								DETECTED_PROJECT='spring-data-ldap'
							elif [[ "${LIB}" == *"mongodb"* ]]; then
								DETECTED_PROJECT='spring-data-mongodb'
							elif [[ "${LIB}" == *"r2dbc"* ]]; then
								DETECTED_PROJECT='spring-data-r2dbc'
							elif [[ "${LIB}" == *"redis"* ]]; then
								DETECTED_PROJECT='spring-data-redis'
							elif [[ "${LIB}" == *"rest"* ]]; then
								DETECTED_PROJECT='spring-data-rest'
							else
								DETECTED_PROJECT='spring-data'
							fi

						# Check support for Spring Batch (https://spring.io/projects/spring-batch#support)
						elif [[ "${E_GROUP}" == "org.springframework.batch"* ]]; then
							DETECTED_PROJECT='spring-batch'

						# Check support for Spring Security (https://spring.io/projects/spring-security#support)
						elif [[ "${E_GROUP}" == "org.springframework.security"* ]]; then
							if [[ "${LIB}" == *"kerberos"* ]]; then
								DETECTED_PROJECT='spring-security-kerberos'
							else
								DETECTED_PROJECT='spring-security'
							fi

						# Check support for Spring HATEOAS (https://spring.io/projects/spring-hateoas#support)
						elif [[ "${E_GROUP}" == "org.springframework.hateoas"* ]]; then
							DETECTED_PROJECT='spring-hateoas'

						# Check support for Spring Cloud (https://spring.io/projects/spring-cloud)
						elif [[ "${E_GROUP}" == "org.springframework.cloud"* ]]; then
							if [[ "${LIB}" == *"spring-cloud-app-broker"* ]]; then
								DETECTED_PROJECT='spring-cloud-app-broker'
							elif [[ "${LIB}" == *"bus"* ]]; then
								DETECTED_PROJECT='spring-cloud-bus'
							elif [[ "${LIB}" == *"circuitbreaker"* || "${E_PACKAGE}" == "hystrix" ]]; then
								DETECTED_PROJECT='spring-cloud-circuitbreaker'
							elif [[ "${LIB}" == *"cli"* ]]; then
								DETECTED_PROJECT='spring-cloud-cli'
							elif [[ "${E_PACKAGE}" == "spring-cloud-commons" || "${E_PACKAGE}" == "spring-cloud-context" ]]; then
								DETECTED_PROJECT='spring-cloud-commons'
							elif [[ "${LIB}" == *"config"* ]]; then
								DETECTED_PROJECT='spring-cloud-config'
							elif [[ "${LIB}" == *"consul"* ]]; then
								DETECTED_PROJECT='spring-cloud-consul'
							elif [[ "${LIB}" == *"contract"* ]]; then
								DETECTED_PROJECT='spring-cloud-contract'
							elif [[ "${E_PACKAGE}" == "spring-cloud-dataflow"* ]]; then
								DETECTED_PROJECT='spring-cloud-dataflow'
							elif [[ "${E_PACKAGE}" == "spring-cloud-function"* ]]; then
								DETECTED_PROJECT='spring-cloud-function'
							elif [[ "${E_PACKAGE}" == "spring-cloud-gateway"* ]]; then
								DETECTED_PROJECT='spring-cloud-gateway'
							elif [[ "${E_PACKAGE}" == *"kubernetes"* ]]; then
								DETECTED_PROJECT='spring-cloud-kubernetes'
							elif [[ "${E_PACKAGE}" == *"netflix"* || "${E_PACKAGE}" == *"hystrix"* ]]; then
								DETECTED_PROJECT='spring-cloud-netflix'
							elif [[ "${E_PACKAGE}" == *"spring-cloud-open-service-broker"* ]]; then
								DETECTED_PROJECT='spring-cloud-open-service-broker'
							elif [[ "${E_PACKAGE}" == *"openfeign"* ]]; then
								DETECTED_PROJECT='spring-cloud-openfeign'
							elif [[ "${LIB}" == *"security"* ]]; then
								DETECTED_PROJECT='spring-cloud-security'
							elif [[ "${E_PACKAGE}" == *"spring-cloud-skipper"* ]]; then
								DETECTED_PROJECT='spring-cloud-skipper'
							elif [[ "${LIB}" == *"sleuth"* ]]; then
								DETECTED_PROJECT='spring-cloud-sleuth'
							elif [[ "${LIB}" == *"spring-cloud-stream-applications"* ]]; then
								DETECTED_PROJECT='spring-cloud-stream-applications'
							elif [[ "${LIB}" == *"spring-cloud-stream"* ]]; then
								DETECTED_PROJECT='spring-cloud-stream'
							elif [[ "${E_PACKAGE}" == *"spring-cloud-task"* ]]; then
								DETECTED_PROJECT='spring-cloud-task'
							elif [[ "${LIB}" == *"vault"* ]]; then
								DETECTED_PROJECT='spring-cloud-vault'
							elif [[ "${LIB}" == *"zookeeper"* ]]; then
								DETECTED_PROJECT='spring-cloud-zookeeper'
							else
								log_console_info "Unknown Spring Cloud library: ${LIB}:${E_VERSION_FULL}"
							fi

						elif [[ "${E_GROUP}" == "org.springframework.pulsar"* ]]; then
							DETECTED_PROJECT='spring-pulsar'

						elif [[ "${E_GROUP}" == "org.springframework.restdocs"* ]]; then
							DETECTED_PROJECT='spring-restdocs'

						elif [[ "${E_GROUP}" == "org.springframework.statemachine"* ]]; then
							DETECTED_PROJECT='spring-statemachine'

						elif [[ "${E_GROUP}" == "org.springframework.webflow"* ]]; then
							DETECTED_PROJECT='spring-webflow'

						elif [[ "${E_GROUP}" == "org.springframework.ws"* ]]; then
							DETECTED_PROJECT='spring-ws'

						elif [[ "${E_GROUP}" == "org.springframework.integration"* ]]; then
							DETECTED_PROJECT='spring-integration'

						elif [[ "${E_GROUP}" == "org.springframework.shell"* ]]; then
							DETECTED_PROJECT='spring-shell'

						elif [[ "${E_GROUP}" == "org.springframework.ldap"* ]]; then
							DETECTED_PROJECT='spring-ldap'

						elif [[ "${E_GROUP}" == "org.springframework.kafka"* ]]; then
							DETECTED_PROJECT='spring-kafka'

						elif [[ "${E_GROUP}" == "org.springframework.graphql"* ]]; then
							DETECTED_PROJECT='spring-graphql'

						elif [[ "${E_GROUP}" == "org.springframework.credhub"* ]]; then
							DETECTED_PROJECT='spring-credhub'

						elif [[ "${E_GROUP}" == "org.springframework.amqp"* ]]; then
							DETECTED_PROJECT='spring-amqp'

						else
							log_console_info "Unknown Spring library: ${LIB}:${E_VERSION_FULL}"
						fi
					fi
				fi

				if [[ -n "${DETECTED_PROJECT:-}" ]]; then
					check_support "${DETECTED_PROJECT}" "${ARCHEO_APP_CSV}" "${LIB}" "${E_VERSION_SHORT}" "${E_VERSION_FULL}"
				fi

				local LIB_TYPE=''
				case "${LIB}" in
				*test* | *junit*)
					####### Test libraries (should not be in application)
					# - "test" in name
					# - Everything in [Testing Frameworks & Tools](https://mvnrepository.com/open-source/testing-frameworks)
					# - Examples: spring-security-test-*.jar / spring-test-*.jar / groovy-test-*.jar / opentest4j-*.jar / testng-*.jar / ant-junit-*.jar / junit-*.jar / junit-jupiter-api-*.jar / junit-platform-commons-*.jar
					LIB_TYPE="test"
					;;
				*mock*)
					####### Mocking (should not be in application)
					# - "mock" in name
					# - Everything in [Mocking](https://mvnrepository.com/open-source/mocking)
					LIB_TYPE="mock"
					;;
				*aspectjweaver*)
					####### Build libraries (should not be in application)
					# - graddle / maven / ant-*.jar / groovy-ant-*.jar / aspectjweaver-*.jar
					# https://mvnrepository.com/search?q=aspectjweaver
					LIB_TYPE="AspectJ Weaver"
					;;
				esac
				if [[ -n "${LIB_TYPE:-}" ]]; then
					# Cut everything after last '@'
					ENTRY_TRIM="${ENTRY%%@*}"
					# Cut everything before first '/'
					ENTRY_CLEAN="${ENTRY_TRIM#*/}"
					# Replace all '/' by ':'
					ENTRY_FINAL="${ENTRY_CLEAN//\//:}"
					log_finding "${ARCHEO_APP_CSV}" "${ENTRY_FINAL}" "${E_VERSION_FULL}" "Undesirable" "Low" "Remove '${LIB_TYPE}' library from production deployment"
				fi
			done <"${ARCHEO_OUTPUT}"

			##### Check for duplicated libraries
			# Extract and sort the unique library names
			LIBRARIES=$(awk -F'/' '{printf("%s/%s\n",$2,$3)}' "${ARCHEO_OUTPUT}" | cut -d '@' -f1 | uniq | sort -u)

			# Loop through each unique library
			while IFS= read -r LIBRARY; do
				# Extract all versions of the current library
				VERSIONS=$(grep "/${LIBRARY}@" "${ARCHEO_OUTPUT}" | awk -F'@' '{print $2}' | sort -u)

				# If there are multiple versions, add one entry
				LIB_COUNT=$(echo "$VERSIONS" | wc -l)
				if [[ ${LIB_COUNT} -gt 1 ]]; then
					LIB="${LIBRARY//\//:}"
					log_finding "${ARCHEO_APP_CSV}" "${LIB}" "Multiple" "Duplicates" "Medium" "'${LIB}' has been found ${LIB_COUNT} times in following versions: ${VERSIONS//$'\n'/' & '}"
				fi
			done <<<"$LIBRARIES"
		fi

		###### 2. Add the aggregate findings count to the CSV file
		COUNT_FINDINGS="n/a"
		if [ -f "${ARCHEO_APP_CSV}" ]; then
			# Count all entries excepted the Info ones
			COUNT_FINDINGS=$(wc -l <(tail -n +2 "${ARCHEO_APP_CSV}" | grep -v ',Info,') | tr -d ' ' | cut -d'/' -f 1)
		fi
		echo "${APP_NAME}${SEPARATOR}${COUNT_FINDINGS}" >>"${RESULT_FILE}"

	done <"${REPORTS_DIR}/list__${GROUP}__all_apps.txt"

	log_console_success "Results: ${RESULT_FILE}"
}

# Download all latest JSON files containing Spring Support information
download_spring_project_support_files() {
	mkdir -p "${CONF_DIR}"
	for KEY in "${!PROJECT_ID_MAP[@]}"; do
		FILENAME="${CONF_DIR}/${KEY}__support-data.json"
		if [ ! -f "${FILENAME}" ]; then
			URL="https://spring.io/page-data/projects/$KEY/page-data.json"
			log_console_info "Downloading configuration for ${KEY} (${FILENAME})"
			curl -Ls "$URL" | jq -r '.result.data.page.support' >"${FILENAME}"
		else
			log_console_info "Configuration for ${KEY} already exists. Skipping download. (${FILENAME})"
		fi
	done
}

function main() {
	#download_spring_project_support_files
	for_each_group generate_csv
}

main
