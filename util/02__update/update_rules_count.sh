#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Count the number rules of each tool used by "Application Portfolio Auditor".
##############################################################################################################

# ----- Please adjust
LOCAL_WINDUP_REPORT="$(pwd)/reports/2023_10_25__12_30_48__large/03__WINDUP__large"

# ------ Do not modify
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
INSTALL_DIR=${SCRIPT_DIR}/../../bin
DIST_DIR=${SCRIPT_DIR}/../../dist
CONF_DIR=${SCRIPT_DIR}/../../conf

# shellcheck source=./../../_shared_functions.sh
source "${SCRIPT_DIR}/../../_shared_functions.sh"
# shellcheck source=./../../_versions.sh
source "${SCRIPT_DIR}/../../_versions.sh"

###### 02 - CSA
CSA_RULES_DIR="${CONF_DIR}/CSA/default-rules"
# Couting the patterns
# RULES_CSA=$(find "${CSA_RULES_DIR}" -type f -name "*.yaml" -exec sed -n '/patterns:/,$p' \{\}  \; | uniq | grep -E -c "^- ")
# Counting the rules files
RULES_CSA=$(find "${CSA_RULES_DIR}" -type f | grep -c "yaml" || true)
echo "02 - CSA: ${RULES_CSA}"

###### 03 - Windup
WINDUP_REPORT="${LOCAL_WINDUP_REPORT}/reports/windup_ruleproviders.html"
COUNT_TABLES=$(grep -c "<table" "${WINDUP_REPORT}")
COUNT_SUCCESS=$(grep -c "success" "${WINDUP_REPORT}")
RULES_WINDUP=$((COUNT_SUCCESS - COUNT_TABLES))
echo "03 - WINDUP: ${RULES_WINDUP}"

###### 04 - WAMT
TMP_DIR="/tmp/wamt"
rm -Rf "${TMP_DIR}"
unzip -o "${DIST_DIR}/containerized/wamt/wamt-${WAMT_VERSION}.zip" -d "${TMP_DIR}" >/dev/null 2>&1
unzip -o "${TMP_DIR}/wamt/binaryAppScanner.jar" -d "${TMP_DIR}" >/dev/null 2>&1
RULES_WAMT=$(grep -r -h "<rule " "${TMP_DIR}/rules" | grep -v "xmlns" | cut -d'"' -f 1-2 | sort | uniq | wc -l | tr -d ' ')
echo "04 - WAMT: ${RULES_WAMT}"
rm -Rf "${TMP_DIR}"

###### 05 - OWASP DC
## Counting CVEs
# Old method - RULES_OWASP=$(grep '"cpe23Uri"' "${DIST_DIR}"/owasp_cache/NVD/nvdcve*.json | cut -d':' -f 4-7 | sort | uniq | wc -l | tr -d ' ')
RULES_OWASP=$(curl --compressed -fsSL 'https://nvd.nist.gov/rest/public/dashboard/statistics?reporttype=countsbystatus' | jq '.vulnsByStatusCounts[] | select(.name=="Total") | .count')
echo "05 - OWASP DC: ${RULES_OWASP}"

# JS Repository
RULES_OWASP_JS=$(grep '"below"' -c "${DIST_DIR}"/owasp_data/jsrepository.json)
echo "05 - OWASP DC JS: ${RULES_OWASP_JS}"

###### 06 - Scancode
# Counting the copyright types
RULES_SCANCODE_COPYRIGHTS=$(curl --compressed -fsSL https://raw.githubusercontent.com/nexB/scancode-toolkit/develop/src/cluecode/copyrights_hint.py | grep -v -E "^#" | grep -v -E "^['\)]" | grep -v "=" | grep -v "from " | sed '/^[[:space:]]*$/d' | grep -v "import " -c)
# Counting the licence types
RULES_SCANCODE_LICENCES=$(curl --compressed -fsSL https://github.com/nexB/scancode-toolkit/tree/develop/src/licensedcode/data/licenses | grep 'a class="js-navigation-open Link--primary" title' | grep ".LICENSE</a></span>" -c)
RULES_SCANCODE=$((RULES_SCANCODE_COPYRIGHTS + RULES_SCANCODE_LICENCES))
echo "06 - Scancode: ${RULES_SCANCODE}"

###### 07 - PMD
TMP_DIR="/tmp/pmd"
rm -Rf "${TMP_DIR}"
unzip "${DIST_DIR}/containerized/pmd/pmd-bin-${PMD_VERSION}.zip" -d "${TMP_DIR}" >/dev/null 2>&1
for FILE in "${TMP_DIR}/pmd-bin-${PMD_VERSION}"/lib/pmd-*.jar; do
	unzip -d "${TMP_DIR}" "${FILE}" '*.xml' >/dev/null 2>&1
done
RULES_PMD=$(ag --nofilename "<rule ref=" "${TMP_DIR}" | grep -v 'deprecated="true"' | sed -e 's/^[ \t]*//' | grep -E "^<rule" | uniq | wc -l | tr -d ' ')
echo "07 - PMD: ${RULES_PMD}"
rm -Rf "${TMP_DIR}"

###### 08 - Linguist
RULES_LINGUIST=$(curl --compressed -fsSL https://github.com/github/linguist/tree/master/vendor/grammars | jq -C | grep 'submoduleDisplayName' | grep -v 'CodeMirror' -c)
echo "08 - Linguist: ${RULES_LINGUIST}"

###### 08 - CLOC
CLOC=${INSTALL_DIR}/cloc-${CLOC_VERSION}/cloc
RULES_CLOC=$("${CLOC}" --show-lang | wc -l | tr -d ' ')
echo "08 - CLOC: ${RULES_CLOC}"

###### 09 - FindSecBugs
RULES_FSB=$(curl --compressed -fsSL https://find-sec-bugs.github.io/ | grep signature | sed -e 's:^.*over \([0-9]*\) unique API signatures.*:\1:')
echo "09 - FSB: ${RULES_FSB}"

###### 10 - MAI
RULES_MAI=$(${CONTAINER_ENGINE} run ${CONTAINER_ENGINE_ARG} --rm --name MAI mai:${MAI_VERSION} verifyrules -d | grep -c Ruleid || true)
echo "10 - MAI: ${RULES_MAI}"

###### 11 - SL SCAN SAST
# Estimate
RULES_SLSCAN="243216"
echo "11 - SL SCAN SAST: ${RULES_SLSCAN}"

###### 12 - Insider SAST
RULES_INSIDER=0
RULE_FILES=(android core csharp ios javascript)
for RULE in "${RULE_FILES[@]}"; do
	COUNT=$(curl --compressed -fsSL "https://raw.githubusercontent.com/insidersec/insider/master/rule/${RULE}.go" | grep "[ \t]*Rule" -c)
	RULES_INSIDER=$((COUNT + RULES_INSIDER))
done
echo "12 - Insider: ${RULES_INSIDER}"

###### 13 - Grype
GRYPE_CACHE_DB="${DIST_DIR}/grype_cache/5/vulnerability.db"
## Counting entries in the vulnerability table
# RULES_GRYPE=$(sqlite3 -batch "${GRYPE_CACHE_DB}" "select COUNT(*) FROM vulnerability;")
# Counting distinct recognized package names
RULES_GRYPE=$(sqlite3 -batch dist/grype_cache/5/vulnerability.db "select COUNT(DISTINCT package_name) FROM vulnerability;")
echo "13 - Grype:${RULES_GRYPE}"

###### 14 - Trivy
pushd "/tmp" &>/dev/null
rm -f main.tar.gz
wget -q https://github.com/aquasecurity/vuln-list/archive/main.tar.gz
RULES_TRIVY=$(tar -ztvf main.tar.gz | grep ".json$" -c)
rm -f main.tar.gz
echo "14 - Trivy:${RULES_TRIVY}"
popd &>/dev/null

###### 15 - OSV
# Todo

###### 16 - Archeo
# Todo

###### 17 - Bearer
# Todo - Retrieve from https://docs.bearer.com/reference/rules/


cat >"${DIST_DIR}/rules.counts" <<EOF
ODC_RULES=${RULES_OWASP}
SCANCODE_RULES=${RULES_SCANCODE}
SLSCAN_RULES=${RULES_SLSCAN}
FSB_RULES=${RULES_FSB}
INSIDER_RULES=${RULES_INSIDER}
GRYPE_RULES=${RULES_GRYPE}
CLOC_RULES=${RULES_CLOC}
LINGUIST_RULES=${RULES_LINGUIST}
MAI_RULES=${RULES_MAI}
PMD_RULES=${RULES_PMD}
WINDUP_RULES=${RULES_WINDUP}
WAMT_RULES=${RULES_WAMT}
CSA_RULES=${RULES_CSA}
TRIVY_RULES=${RULES_TRIVY}
OSV_RULES=108137
ARCHEO_RULES=55
BEARER_RULES=360
EOF
