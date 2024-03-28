#!/usr/bin/env bash
set -x

LATEST_TAG="idea/${1}"
REPO_URL=https://github.com/JetBrains/intellij-community.git
TMP_DIR=/intellij
DIST_DIR=/build

export JAVA_VERSION='21'

function stream_edit() {
	sed -i -e "${1}" "${2}"
}

function check_built_java_version() {
	CLASS="${1}"
	if [[ -n "$(command -v od)" ]]; then
		JAVA_VERSION_BUILD=$(od -t d -j 7 -N 1 "${CLASS}" | head -1 | awk '{print $2 - 44}')
		if [[ "${JAVA_VERSION_BUILD}" != "${JAVA_VERSION}" ]]; then
			echo "Build JAR (Java ${JAVA_VERSION_BUILD}) does not match expected version (${JAVA_VERSION})"
			exit 1
		fi
	else
		echo "Unable to validate built JAR version as 'od' is not installed"
		exit 1
	fi
}

# Retrieve latest idea tag
echo "Downloading 'Fernflower' from Intellij-Community '${LATEST_TAG}'"

# Do not retrieve the full repository
git clone --depth=1 --branch "${LATEST_TAG}" --filter=blob:none --sparse "${REPO_URL}"
cd intellij-community || exit 1

# Selectively checkout sub directory
git sparse-checkout set plugins/java-decompiler/engine
cd plugins/java-decompiler/engine || exit 1

# Build Fernflower using the configured $JAVA_VERSION
stream_edit "s/targetCompatibility '.*'/targetCompatibility '${JAVA_VERSION}'/" build.gradle
GRADLE_OPTS="-Dorg.gradle.daemon=false" gradle assemble

check_built_java_version "${TMP_DIR}/intellij-community/plugins/java-decompiler/engine/build/classes/java/main/org/jetbrains/java/decompiler/ClassNameConstants.class"

cp "${TMP_DIR}/intellij-community/plugins/java-decompiler/engine/build/libs/fernflower.jar" "${DIST_DIR}/fernflower.jar"
