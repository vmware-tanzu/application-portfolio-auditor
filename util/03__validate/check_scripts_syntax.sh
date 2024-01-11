#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Check the syntax of all scripts Shell and Python scripts of "Application Portfolio Auditor".
##############################################################################################################

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
HOME_DIR="${SCRIPT_DIR}/../.."

ARE_PREREQUISITES_MET=true

# Checks mode
function check_package() {
	PYTHON_SPEC="${1}"
	python -c "import sys; import importlib; from importlib import util; package_spec = importlib.util.find_spec(\"${PYTHON_SPEC}\"); exit_code = 0 if (package_spec is None) else 1; sys.exit(exit_code);" &&
		{
			echo "Missing python library: ${PYTHON_SPEC} - Install with: 'pip install --upgrade ${PYTHON_LIB}'"
			ARE_PREREQUISITES_MET=false
		}
}

check_package pyflakes
check_package pylint

if [ "${ARE_PREREQUISITES_MET}" = false ]; then
	exit 1
fi

while read -r SCRIPT; do
	# Install: pip install --upgrade pyflakes
	# https://github.com/PyCQA/pyflakes
	echo "PyFlakes"
	python -m pyflakes "${SCRIPT}"

	# Install: pip install pylint --upgrade
	# https://github.com/PyCQA/pylint/
	echo "PyLint"
	pylint "${SCRIPT}" | grep -v "C0301" | grep -v '^[- ]*$'
done < <(find "${HOME_DIR}/util" -maxdepth 3 -mindepth 1 -type f -name '*.py' | sort)

while read -r SCRIPT; do
	bash -n "${SCRIPT}"
	COUNT=$(shellcheck "${SCRIPT}" -x | grep -c "In .* line [0-9]*:" || true)
	echo "Shellcheck issues: ($(basename "${SCRIPT}"))              ${COUNT}"
done < <(find "${HOME_DIR}" -maxdepth 3 -mindepth 1 -type f -name '*.sh' -not -path "${HOME_DIR}/reports/*" | sort)

COUNT="$(shellcheck "${HOME_DIR}"/*.sh -x | grep -c "In .* line [0-9]*:" || true)"
echo "Shellcheck issues: (ALL)              ${COUNT}"
