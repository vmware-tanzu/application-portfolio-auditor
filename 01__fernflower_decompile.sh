#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Decompile all binary applications (EAR/WAR/JAR) in ${APP_DIR_IN} grouped in sub-folders using ...
#   "Fernflower" - https://github.com/JetBrains/intellij-community/tree/master/plugins/java-decompiler/engine
#
# Embedded libraries are not decompiled ("ignored") if either ...
#  -> one entry in ${FERNFLOWER_EXCLUDED_LIST} matches their name
#  -> their SHA1 sum is on ${FERNFLOWER_SHA1_EXCLUDED_LIST}
#  -> their SHA1 matches an entry of a maven public repository (${MAVEN_SEARCH_URL})
#
# First actually working analytical decompiler for Java and probably for a high-level programming language in general.
##############################################################################################################

# ----- Please adjust

# Fernflower log level
FERNFLOWER_LOG_LEVEL="ERROR"

# Public maven search repository used to search SHA1 sums and ignore public libraries
USE_MAVEN_SEARCH="true"
MAVEN_SEARCH_BASE_URL="https://search.maven.org"
MAVEN_SEARCH_URL="${MAVEN_SEARCH_BASE_URL}/solrsearch/select?q=1:"

# FIXME - Findjar is unfortunately not available anymore - could be replaced by https://jar-download.com/maven-repository-class-search.php)
USE_FINDJAR="false"
FINDJAR_BASE_URL="https://www.findjar.com"

# File listing patterns of files to be ignored (neither unziped nor decompiled)
FERNFLOWER_EXCLUDED_LIST="${CURRENT_DIR}/conf/Fernflower/excluded_names.txt"
# File listing SHA1 sums of libraries to be ignored (neither unzipped nor decompiled)
FERNFLOWER_SHA1_EXCLUDED_LIST="${CURRENT_DIR}/conf/Fernflower/excluded_sha1.txt"
# File listing the MANIFEST.MF vendors of files to be ignored (neither unziped nor decompiled)
FERNFLOWER_EXCLUDED_VENDORS_LIST="${CURRENT_DIR}/conf/Fernflower/excluded_vendors.txt"

# ------ Do not modify
STEP=$(get_step)

VERSION="${FERNFLOWER_VERSION}"

# List of all archives that have been decompiled
FERNFLOWER_UNPACKED_LIBS_LIST="${REPORTS_DIR}/${STEP}__Fernflower__unpacked_libs.txt"
FERNFLOWER_ALL_LIBS_LIST="${REPORTS_DIR}/${STEP}__Fernflower__all_libs.txt"
MVNREPOSITORY_BASE_URL="https://mvnrepository.com"

export LOG_FILE=${REPORTS_DIR}/${STEP}__Fernflower.log

# Load a property from a properties files
function prop() {
	grep "${1}" "${2}" | cut -d'=' -f2
}

# Unpack and delete an archive
function unpack() {
	FILE="${1}"
	log_console_info "Unpacking '${FILE}'"
	OUTPUT_DIR="${1%.*}_${1##*.}"
	[[ -d "${OUTPUT_DIR}" ]] && rm -Rf "${OUTPUT_DIR}"
	mkdir -p "${OUTPUT_DIR}"
	UNZIP_OPTS=(-o -P pass "${FILE}" -d "${OUTPUT_DIR}")
	# shellcheck disable=SC2143
	if [[ -n "$(unzip -l "${FILE}" | grep -E ' /$')" ]]; then
		UNZIP_OPTS+=(-x)
		UNZIP_OPTS+=(-/)
	fi
	unzip "${UNZIP_OPTS[@]}" >&6 2>&1
	RC=$?
	if [[ ${RC} -ne 0 ]]; then
		log_console_error "Error while extracting '${FILE}' (${RC})"
		# Remove temporary directory.
		rm -Rf "${OUTPUT_DIR}"
		# Rename the file reflecting the encountered error.
		mv "${FILE}" "${FILE}.${RC}.corrupted"
	fi
	rm -f "${FILE}"
}

# Repack applications to a single huge application without sub-WAR/JAR file
function unpack_and_decompile() {
	APP_DIR_INCOMING="${1}"
	GROUP=$(basename "${APP_DIR_INCOMING}")
	APP_DIR_SRC="${APP_DIR_INCOMING}/src"
	APP_DIR_TMP="${APP_DIR_INCOMING}/tmp"

	rm -Rf "${APP_DIR_SRC}" "${APP_DIR_TMP}"
	mkdir -p "${APP_DIR_SRC}" "${REPORTS_DIR}"

	log_analysis_message "group '${GROUP}'"

	while read -r APP; do

		mkdir -p "${APP_DIR_TMP}"

		log_console_step "Preparing '${APP}' ... "
		cp "${APP}" "${APP_DIR_TMP}"

		APP_NAME=$(basename "${APP}")

		while [ "$(find "${APP_DIR_TMP}" -type f -iname '*.war' \
			-o -type f -iname '*.ear' \
			-o -type f -iname '*.jar' \
			-o -type f -iname '*.rar' \
			-o -type f -iname '*.gar' \
			-o -type f -iname '*.har' \
			-o -type f -iname '*.sar' | wc -l | tr -d ' ')" -gt 0 ]; do

			while read -r ARCHIVE; do
				PARENT_DIR_NAME=$(basename "$(dirname "${ARCHIVE}")")
				TMP_DIR_NAME=$(basename "${APP_DIR_TMP}")
				ARCHIVE_SHORT_NAME="${ARCHIVE:${#APP_DIR_TMP}+1}"
				SHA1_LONG=$(sha1sum "${ARCHIVE}")
				SHA1=$(echo "${SHA1_LONG}" | cut -d' ' -f 1)

				if [[ "${TMP_DIR_NAME}" == "${PARENT_DIR_NAME}" ]]; then
					# Unpack every app present in the parent directory in all cases
					unpack "${ARCHIVE}" "${LOG_FILE}"
					echo "${SHA1} [UNPACKED APP    ] ${ARCHIVE_SHORT_NAME}" >>"${FERNFLOWER_ALL_LIBS_LIST}"
				elif [[ -f "${FERNFLOWER_EXCLUDED_LIST}" ]] && basename "${ARCHIVE}" | grep -q -f "${FERNFLOWER_EXCLUDED_LIST}"; then
					# Ignore archives based on their name (pattern list)
					log_console_info "Ignoring (NAME) '${ARCHIVE}'"
					mv "${ARCHIVE}" "${ARCHIVE}.ignored_name"
					echo "${SHA1} [IGNORED NAME    ] ${ARCHIVE_SHORT_NAME}" >>"${FERNFLOWER_ALL_LIBS_LIST}"
				elif [[ -f "${FERNFLOWER_SHA1_EXCLUDED_LIST}" ]] && sha1sum "${ARCHIVE}" | cut -d' ' -f 1 | grep -q -f "${FERNFLOWER_SHA1_EXCLUDED_LIST}"; then
					# Ignore archives based on their SHA1 (list)
					log_console_info "Ignoring (SHA1) '${ARCHIVE}'"
					mv "${ARCHIVE}" "${ARCHIVE}.ignored_sha1"
					echo "${SHA1} [IGNORED SHA1    ] ${ARCHIVE_SHORT_NAME}" >>"${FERNFLOWER_ALL_LIBS_LIST}"
				else
					declare COUNT_FOUND
					if [[ "${USE_MAVEN_SEARCH}" == "true" ]]; then
						COUNT_FOUND=$(curl -s "${MAVEN_SEARCH_URL}${SHA1}" | jq ".response.numFound")
					fi
					if [[ -z "${COUNT_FOUND}" || "${COUNT_FOUND}" == "0" ]]; then
						# Archive not on exclude lists (SHA1/pattern), and not on public maven repo.
						HAS_TO_UNPACK_ARCHIVE="true"

						# Check if one 'pom.properties' file is present and validate the maven coordinates against "mvnrepository.com"
						set +e
						unzip -Z1 "${ARCHIVE}" | grep '^META-INF/maven/.*pom.properties$' >"${ARCHIVE}.props"
						set -e
						POM_PROPS_COUNT=$(wc -l "${ARCHIVE}.props" | awk '{print $1}' | tr -d ' ')
						if [[ "${POM_PROPS_COUNT}" == "1" ]]; then
							ARCHIVED_POM_PROPS=$(head -n 1 "${ARCHIVE}.props")
							# Extract the 'pom.properties' file
							POM_PROPS="${ARCHIVE}.pom.properties"
							set +e
							unzip -p "${ARCHIVE}" "${ARCHIVED_POM_PROPS}" >"${POM_PROPS}"
							set -e
							POM_G=$(prop groupId "${POM_PROPS}")
							POM_A=$(prop artifactId "${POM_PROPS}")
							POM_V=$(prop version "${POM_PROPS}")
							MVN_REPO_URL="${MVNREPOSITORY_BASE_URL}/artifact/${POM_G}/${POM_A}/${POM_V}"

							if curl -s "${MVN_REPO_URL}" | grep -q "<div id=\"maincontent\">"; then
								HAS_TO_UNPACK_ARCHIVE="false"
								log_console_info "Ignoring (MVN_REPO) '${ARCHIVE}'"
								# Add SHA1 to the excluded list
								echo "${SHA1}" >>"${FERNFLOWER_SHA1_EXCLUDED_LIST}"
								mv "${ARCHIVE}" "${ARCHIVE}.ignored_maven_repo"
								echo "${SHA1} [IGNORED MVN_REPO] ${ARCHIVE_SHORT_NAME}" >>"${FERNFLOWER_ALL_LIBS_LIST}"
							else
								HAS_TO_UNPACK_ARCHIVE="true"
							fi
						fi
						rm -f "${ARCHIVE}.props"

						if [[ "${HAS_TO_UNPACK_ARCHIVE}" == "true" ]]; then

							# Check "Implementation-Vendor" (if set) in the MANIFEST.MF file to exclude well known ones
							set +e
							ARCHIVED_MF=$(unzip -Z1 "${ARCHIVE}" | grep '^META-INF/MANIFEST.MF$')
							set -e
							if [[ -n "${ARCHIVED_MF}" ]]; then
								MF="${ARCHIVE}.MANIFEST.MF"
								#DATE_EXTRACT="$(unzip -l "${ARCHIVE}" | grep 'META-INF/MANIFEST.MF$' | rev | cut -d' ' -f4-5 |rev)"
								#echo "    Date (MANIFEST.MF): ${DATE_EXTRACT}"
								#grep -m1 'Name:' "${MF}"
								#grep -m1 'Extension-Name:' "${MF}"
								#grep -m1 'Implementation-Title:' "${MF}"
								#grep -m1 'Implementation-URL:' "${MF}"
								set +e
								unzip -p "${ARCHIVE}" "${ARCHIVED_MF}" >"${MF}"
								set -e
								VENDOR=$(grep -m1 'Implementation-Vendor:' "${MF}" | tr -d '\n' | tr -d '\r' | cut -d' ' -f2- | tr -d '"')
								if echo "${VENDOR}" | grep -q -f "${FERNFLOWER_EXCLUDED_VENDORS_LIST}"; then
									HAS_TO_UNPACK_ARCHIVE="false"
									log_console_info "Ignoring (VENDOR '${VENDOR}') '${ARCHIVE}'"
									mv "${ARCHIVE}" "${ARCHIVE}.ignored_vendor"
									echo "${SHA1} [IGNORED VENDOR  ] ${ARCHIVE_SHORT_NAME}" >>"${FERNFLOWER_ALL_LIBS_LIST}"
								elif [[ -n "${VENDOR}" ]]; then
									log_console_warning "New unknown vendor detected (candidate for 'FERNFLOWER_EXCLUDED_VENDORS_LIST'): ${VENDOR}"
								fi
								rm -f "${MF}"
							fi

							# Extract class with the longest package+class name, and use findjar to find a potential existing library
							if [[ "${USE_FINDJAR}" == "true" && "${HAS_TO_UNPACK_ARCHIVE}" == "true" ]]; then
								# Get the class with the longest package+class name
								set +e
								LONGEST_NAME=$(unzip -Z1 "${ARCHIVE}" | grep class | cut -d'.' -f1 | cut -d'$' -f1 | sort | uniq | awk 'length > max_length { max_length = length; longest_line = $0 } END { print longest_line }')
								set -e
								# Extract the prefix of the analyzed archive
								ARCHIVE_PREFIX=$(basename "${ARCHIVE}" | tr '.' '-' | tr '_' '-' | sed 's/[0-9]*//g' | cut -d'-' -f1 | tr '[:upper:]' '[:lower:]')
								FINDJAR_RESULTS="${ARCHIVE}.findjar"
								# Query findjar to find potential matching libraries (timeout in seconds set by "-m") ...
								curl -m 3 -s "${FINDJAR_BASE_URL}/class/${LONGEST_NAME}" | sed -n '/<table class="results">/,/<\/table>/p' | grep "<a href" | rev | cut -d '>' -f3 | rev | cut -d '<' -f1 >"${FINDJAR_RESULTS}"
								JAR_COUNT=$(wc -l <"${FINDJAR_RESULTS}" | tr -d ' ')
								JAR_COUNT_PREFIX=$(grep -i -c "${ARCHIVE_PREFIX}" "${FINDJAR_RESULTS}" | tr -d ' ')
								log_console_info "      -> Searching for: ${LONGEST_NAME} (${JAR_COUNT} entries, incl. ${JAR_COUNT_PREFIX} containing '${ARCHIVE_PREFIX}')"
								rm -f "${FINDJAR_RESULTS}"
								if [[ -z "${JAR_COUNT_PREFIX}" || "${JAR_COUNT_PREFIX}" == "0" ]]; then
									HAS_TO_UNPACK_ARCHIVE="true"
								else
									HAS_TO_UNPACK_ARCHIVE="false"
									log_console_info "Ignoring (FINDJAR) '${ARCHIVE}'"
									echo "${SHA1} [IGNORED FINDJAR ] ${ARCHIVE_SHORT_NAME}" >>"${FERNFLOWER_ALL_LIBS_LIST}"
									mv "${ARCHIVE}" "${ARCHIVE}.ignored_findjar"
								fi
							fi

							echo "${SHA1}  ${ARCHIVE_SHORT_NAME}" >>"${FERNFLOWER_UNPACKED_LIBS_LIST}"
							echo "${SHA1} [UNPACKED LIB    ] ${ARCHIVE_SHORT_NAME}" >>"${FERNFLOWER_ALL_LIBS_LIST}"

							if [[ "${HAS_TO_UNPACK_ARCHIVE}" == "true" ]]; then
								unpack "${ARCHIVE}" "${LOG_FILE}"
							fi
						fi

					else
						# Ignore archive present in public maven repository
						log_console_info "Ignoring (PUB_MVN) '${ARCHIVE}'"
						# Add SHA1 to the excluded list
						echo "${SHA1}" >>"${FERNFLOWER_SHA1_EXCLUDED_LIST}"
						echo "${SHA1} [IGNORED PUB MVN ] ${ARCHIVE_SHORT_NAME}" >>"${FERNFLOWER_ALL_LIBS_LIST}"
						mv "${ARCHIVE}" "${ARCHIVE}.ignored_maven"
					fi
				fi
			done < <(find "${APP_DIR_TMP}" -type f -iname '*.war' \
				-o -type f -iname '*.ear' \
				-o -type f -iname '*.jar' \
				-o -type f -iname '*.rar' \
				-o -type f -iname '*.gar' \
				-o -type f -iname '*.har' \
				-o -type f -iname '*.sar')
		done

		APP_SRC="${APP_DIR_SRC}/${APP_NAME}"
		rm -Rf "${APP_SRC}"
		mkdir -p "${APP_SRC}"

		APP_TMP=${APP_DIR_TMP}/${APP_NAME}
		APP_TMP_NAME="${APP_TMP%.*}_${APP_TMP##*.}"

		if [[ "${PRE_ANALYSIS_ACTIVE}" == "false" ]]; then
			log_console_step "Decompiling '${APP_TMP_NAME}' with a total of $(find "${APP_TMP_NAME}" -name '*.class' | wc -l | tr -d ' ') classes ($(date))"
			## A number of files cause issues for Fernflower, either due to their type, or the
			## file names not being UTF-8... Since all we _need_ are the EAR and class files, we should remove _everything_ else
			#find . \! \( -name '*.ear' -o -name '*.class' -o -name '*.xml' -o -name '*.jsp' \) -type f -delete
			set +e
			${CONTAINER_ENGINE} run --rm -v "${APP_TMP_NAME}:/class:ro" -v "${APP_SRC}:/src:delegated" "${CONTAINER_IMAGE_NAME_FERNFLOWER}" -log="${FERNFLOWER_LOG_LEVEL}" "/class" "/src" >>"${LOG_FILE}" 2>&1
			RC=$?
			set -e
			if [[ ${RC} -ne 0 ]]; then
				log_console_error "An error occurred during the decompilation."
			fi
		else
			log_console_step "Identified '${APP_TMP_NAME}' with a total of $(find "${APP_TMP_NAME}" -name '*.class' | wc -l | tr -d ' ') classes"
		fi
		# Note: Here we do not delete ${APP_DIR_TMP} as it creates some issues with the containerized fernflower execution. 
		rm -Rf "${APP_TMP}" "${APP_TMP_NAME}"

	done <"${REPORTS_DIR}/list__${GROUP}__java-bin.txt"

	rm -Rf "${APP_DIR_TMP}"

}

function check_status() {
	SITE_NAME="${1}"
	SITE_URL="${2}"
	SITE_STATUS=$(curl -m 3 -I "${SITE_URL}" 2>/dev/null | head -n 1 | cut -d$' ' -f2)
	[ -z "${SITE_STATUS}" ] && SITE_STATUS="Timeout"
	log_console_info "Site status for '${SITE_NAME}' (${SITE_URL}): ${SITE_STATUS}"
}

function main() {

	if [[ "${DEBUG}" == "true" ]]; then
		set -x
		exec 6>&1
		FERNFLOWER_LOG_LEVEL="INFO"
	else
		exec 6>/dev/null
	fi

	if [[ -n $(${CONTAINER_ENGINE} images -q "${CONTAINER_IMAGE_NAME_FERNFLOWER}") ]]; then

		set +e
		log_tool_info "Fernflower v${VERSION}"

		[[ "${USE_FINDJAR}" == "true" ]] && { check_status "findjar.com" "${FINDJAR_BASE_URL}"; }
		check_status "Maven Search" "${MAVEN_SEARCH_BASE_URL}"
		check_status "MVN Repository" "${MVNREPOSITORY_BASE_URL}"

		for_each_group unpack_and_decompile

		if [[ "${PRE_ANALYSIS_ACTIVE}" == "true" ]]; then

			COUNT_APPS=$(grep -c "UNPACKED APP" "${FERNFLOWER_ALL_LIBS_LIST}" || true)
			COUNT_UNPACKED_LIBS=$(grep -c "UNPACKED LIB" "${FERNFLOWER_ALL_LIBS_LIST}" || true)
			COUNT_IGNORED_LIBS=$(grep -c "IGNORED" "${FERNFLOWER_ALL_LIBS_LIST}" || true)
			COUNT_IGNORED_LIBS_NAME=$(grep -c "IGNORED NAME" "${FERNFLOWER_ALL_LIBS_LIST}" || true)
			COUNT_IGNORED_LIBS_SHA1=$(grep -c "IGNORED SHA1" "${FERNFLOWER_ALL_LIBS_LIST}" || true)
			COUNT_IGNORED_LIBS_MVN_REPO=$(grep -c "IGNORED MVN_REPO" "${FERNFLOWER_ALL_LIBS_LIST}" || true)
			COUNT_IGNORED_LIBS_PUB_MVN=$(grep -c "IGNORED PUB MVN" "${FERNFLOWER_ALL_LIBS_LIST}" || true)
			COUNT_IGNORED_LIBS_VENDOR=$(grep -c "IGNORED VENDOR" "${FERNFLOWER_ALL_LIBS_LIST}" || true)
			COUNT_IGNORED_LIBS_FINDJAR=$(grep -c "IGNORED FINDJAR" "${FERNFLOWER_ALL_LIBS_LIST}" || true)

			log_console ""
			log_console_success "${COUNT_APPS} Java binary applications identified with $((COUNT_UNPACKED_LIBS + COUNT_IGNORED_LIBS)) embedded libs:"
			log_console_sub_step "${COUNT_UNPACKED_LIBS} libs will be decompiled"
			[[ ${COUNT_IGNORED_LIBS_NAME} -ne 0 ]] && { log_console_sub_step "${COUNT_IGNORED_LIBS_NAME} libs are ignored due to their name (exclusion list: ${FERNFLOWER_EXCLUDED_LIST})"; }
			[[ ${COUNT_IGNORED_LIBS_SHA1} -ne 0 ]] && { log_console_sub_step "${COUNT_IGNORED_LIBS_SHA1} libs are ignored due to their SHA1 signature (exclusion list: ${FERNFLOWER_SHA1_EXCLUDED_LIST})"; }
			[[ ${COUNT_IGNORED_LIBS_MVN_REPO} -ne 0 ]] && { log_console_sub_step "${COUNT_IGNORED_LIBS_MVN_REPO} libs are ignored due to their presence in MVNRepository (${MVNREPOSITORY_BASE_URL})"; }
			[[ ${COUNT_IGNORED_LIBS_PUB_MVN} -ne 0 ]] && { log_console_sub_step "${COUNT_IGNORED_LIBS_PUB_MVN} libs are ignored due to their presence in a public maven repo (${MAVEN_SEARCH_BASE_URL})"; }
			[[ ${COUNT_IGNORED_LIBS_VENDOR} -ne 0 ]] && { log_console_sub_step "${COUNT_IGNORED_LIBS_VENDOR} libs are ignored due to their vendor name (exclusion list: ${FERNFLOWER_EXCLUDED_VENDORS_LIST})"; }
			[[ ${COUNT_IGNORED_LIBS_FINDJAR} -ne 0 ]] && { log_console_sub_step "${COUNT_IGNORED_LIBS_FINDJAR} libs are ignored due to their longest class name detected on findjar (${FINDJAR_BASE_URL})"; }

			if [[ ${COUNT_UNPACKED_LIBS} -ne 0 ]]; then
				log_console ""
				log_console_warning "Please review the ${COUNT_UNPACKED_LIBS} Java libraries list in ${FERNFLOWER_UNPACKED_LIBS_LIST} and if they are not self-written consider ..."
				log_console_sub_step "adding their SHA1 to your exclusion list: ${FERNFLOWER_SHA1_EXCLUDED_LIST}"
				log_console_sub_step "adding their name to your exclusion list (regex): ${FERNFLOWER_EXCLUDED_LIST}"
			fi

			log_console ""
		fi
		set -e

	else
		log_console_error "Fernflower decompilation canceled. Container image not available: '${CONTAINER_IMAGE_NAME_FERNFLOWER}'"
		exit
	fi
}

main
