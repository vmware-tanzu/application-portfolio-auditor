#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Validate the links present in the CSA rules ('CSA') or in the cookbooks ('CB')
##############################################################################################################

## WARNING: The generated scripts probably only work on MacOS due to the 'xargs -I@' and 'grep -r' usages.

# ----- Please adjust

# Cookies have been obtained from google chrome after opening 'https://app-transformation-cookbook-internal.cfapps.io/' (developer mode -> network -> copy for curl)
COOKIE_GITHUB="_device_id=1a32ab1d249dbfe820ae695fb85268fd; user_session=vj1m3C79JqbgncONg3RN2PZCzH_7A80MK-FkM_NsvSx8J8Mg; __Host-user_session_same_site=vj1m3C79JqbgncONg3RN2PZCzH_7A80MK-FkM_NsvSx8J8Mg; dotcom_user=Maarc; tz=Europe%2FBerlin; _octo=GH1.1.1527509224.1584740996; logged_in=yes; has_recent_activity=1; _gh_sess=%2FlT2HZ9rFp48%2BDvsTZj9%2FgAot9n3rCHJReuF7kEPVksBdyCUwybQrH3NTypiotzYP%2BFN3oS1JO3aaFmSSq3i%2BWJee4j0VkA7RiEeXfzLxkgLj8bVsOBgPORuO1wPyqqeM8XZBPP8g1IwWPVGItBIo%2FZFCDcAZ%2FgJ9IAdZ1qewfpbUgUUmqfqjkv8JoSot%2F7tkpXhSoWLvg03EPq5ZryX5wK3vOCR4dVsojRsZMspVDQjUy%2BosThRcpEZhtkqwMFo0EigONxStYr7G5drTZTFg%2FQTK72zTAtNddHFBXN7fM8huOVd139yhmkBTCTd1U4G%2FJbp4J%2FFSLTuRbRx6SYg63f5uTESuQJ2fBmEXjkwsvV9MinUFnk3UKAxAV%2FT66n8mZ0vgnVvykAqEHf0aeAQHMmeymKk1Ry2ECvrX2y2bOZr5dPN8u2m6egtbAfXHW%2FAq9Zw5icB7wYp1U%2BG1Zg7bkhsY5QigTiuHcVuF9pWqj%2FxHImPXezf6PNebw%2FthS%2B3B1d8D75%2BaMRg1YLuRzA8xTMbMNA2x4uEwT8uQWNwxyFQ2b4lXVMpf6GHcW7UcGMFCEVBqBsgbHastybyAEkvvXwhZ1GD1brhuZP%2Be73gG%2BZnYvGqF1pinHR9u1OJhbevKrx2OrfJTel7OwLLLm4jy3bEgTt%2F8ScniGCrE2YhWBjQPF4n%2BRnVMdcf%2FJZaFKvhCE9mkQFcQDsWZTunzRk%2BGsbujLEJyp%2B5WVHdg5jHpUfXMB1WHnFVvIOjyQeFsGU7fvuuxicRmrQ4it1boqeQEerjW9bwVXGrgSX8U36K0xaO%2BS3r8ziTs4pWcBsOdcbMV%2B0i3YNRdjMDN%2FtlFXE%2FBZ%2B0I3Ww04vH6BQNBA3tg%2FA4RwfDRpA2jdtHjOmo9P2ufNWa%2BUfPcJgsYIHyEUW26QmzpiWvw3AoK9zMIm3LklihMwNUISjvPizV4VJxt0HTsC5UOz0zmh8UQTN5bjAmYyCb7BPLmiryrwIC4aw8FDEmh4u1up0PDCQ%2FV4pJHwbpUa0emhZbC6BoKVSw2%2FmIFQ6FOAnnqnUOmy90kH6m3P87BhTfAGoPxQklbU3H0Ec%2Fr6TwBXAwFozSibzF0RZN%2BjQTcNdB%2FZkiyZGfa7go4Hne%2FkKWxNWDgB%2B5YdLsEGiyk8HHQ7ZshittimoYpTj6xd8cYnfCxBf7SOU6pvqGl02HFIrGsNHBei6ybPCKtZ487CkuPHPVX6cFSmssuM94tHT%2BitAb%2FTaTxBJ0J4X8SUULx3XasbCfCYrFDe%2BiTtLieX0Dl%2BEK6TasmdWXycctKnQOa7z3cXzcAjNXNr0s13r6JkT7z6AL1Oa%2BRzstQBR9wZKRJ4J8KV8CI3eRvagzSstn%2BiDNm9dMaEy0jX%2Fo4lD2p1fCpzzL1pH3kDUGWpp43hJIEBWF6t91rX7455vi5oHCekHfUBpwPC5DHf175oyqunxeJx7ddfGgAyMCmhGEhIhmonZdJaeHajOeFr%2BvKVhaDlrFiKDVWf9xEh4I76gE%2FyFo8v8%2Fv80tzlvAT0t4Xlcjp498r7rP4u1m%2BvSN53%2BttLEJ8Q6XSFRjBHHp5kZLqZATh0gtu3vmpMP7KoFZnJ0DAzDA0YF2J8NaD3X6YjTOQ34JJmvlwnT8Nl8zobj1tNSn8pQWoV4a85EaxACuS9K5J1ds3Iq06wSAh8B%2B%2FEvnB%2FwmRXLhWXn1%2FLF4rGkJbIetRle62XlTPm35ZTNn%2B8%2F%2FHqTXSvrRW%2FJtRC88JocY9oEEXD7m0CUNCSoY5FLjztS5o8ve%2B4opkMY8YphNXGrNxOxLhD9MLOTeyxl8nucl84%2FCoDe94N%2Bc7cJZe8x3hfDP84uzsBojg00IboujHhalbBMgswbyQu7Lbd97qUZCd8HL7QMw%2BNc9Z80qpi%2FWf1M1IC7pTLYEz0YZ5f6JYV3mlMQig8cT1qWYDDlJvY%2FFYxxBHsDDD2YGPdrzniy573ih%2F%2F4WxKT0I%2FAFT0TuNfVbWCNoYFdu%2B9dRAu33CD%2Fl1VtGakO8OX8oD6s37ei8VQjvR4GjM3EeNHUKIjDSNbNjzMfKDczZYDxth7KMajzeuzHzbnlsc0AP0DjvrY3e5EQX1IecjflP%2B9GvU5kiztrjrA%3D%3D--q0Y5ya1200%2BGpRNs--4AoMxWOuBVWR98Z9NUP0yQ%3D%3D"

# Files containing the recommended changes with pre-generated commands
OUTPUT="$(pwd)/recommendations.txt"

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
IGNORED_URLS="${SCRIPT_DIR}/check_links__ignored_urls.txt"

# ------ Do not modify
TARGET="${1}"
TARGET_DIR="${2}"

GREEN='\033[0;32m'
RED='\033[0;31m'
ORANGE='\033[0;33m'
NORMAL='\033[0m'

function check_site() {
	SITE="${1}"
	echo -e "\n>>> ${SITE}"
	ARGS=(s
		-seeeeee
		--head "${SITE}"
	)

	if echo "${SITE}" | grep -q "github.com"; then
		echo "    [Pivotal GitHub]"
		# Additional parameters for references in Pivotal GitHub
		ARGS+=(
			-H 'Connection: keep-alive'
			-H 'Cache-Control: max-age=0'
			-H 'Upgrade-Insecure-Requests: 1'
			-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.106 Safari/537.36'
			-H 'Sec-Fetch-Dest: document'
			-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9'
			-H 'Sec-Fetch-Site: none'
			-H 'Sec-Fetch-Mode: navigate'
			-H 'Sec-Fetch-User: ?1'
			-H 'Accept-Language: en-US,en;q=0.9'
			-H "Cookie: ${COOKIE_GITHUB}"
			-H 'If-None-Match: W/"83d7e0d4bf32d26080a8735827bf3e68"'
		)
	fi

	STATUS=$(curl "${ARGS[@]}" | head -n 1 | tr -d '\n') 2>/dev/null
	echo "    ${STATUS}"
	if echo "${STATUS}" | grep -q -e "HTTP/1.[01] [23].." -e "HTTP/2[\.01]* [23].."; then
		# Move permanently
		if echo "${STATUS}" | grep -qE "301|302"; then
			NEW_LOCATION=$(curl -s --head "${SITE}" | grep -i "location: " | cut -d' ' -f2 | tr -d '\n\r') 2>/dev/null
			if [[ "${SITE}" == http://www14.software.ibm.com/webapp/wsbroker/redirect\?version* ]]; then
				echo -e "${GREEN}    [INFO]  IBM documentation. Ignoring redirect to 'latest'.${NORMAL}"
			else
				echo -e "${ORANGE}    [WARN]  Replace with new location: ${NEW_LOCATION}${NORMAL}"
				{
					echo "#>> RELOCATE (${SITE})"
					echo "grep -r '${SITE}' . | cut -d ':' -f1 | xargs -I@ sed -i '' -e 's|${SITE}|${NEW_LOCATION}|g' @"
					echo ""
				} >>"${OUTPUT}"
			fi
		elif echo "${STATUS}" | grep -q "200"; then
			echo -e "${GREEN}    [INFO]  Site available${NORMAL}"
		else
			echo -e "${ORANGE}    [WARN]  Site probably available. Please check new status message.${NORMAL}"
			{
				echo "#>> VALIDATE (${SITE})"
				echo "grep -r '${SITE}' ."
				echo ""
			} >>"${OUTPUT}"
		fi
	else
		if echo "${SITE}" | grep -q -i -e "localhost" -e "127.0.0.1"; then
			echo -e "${ORANGE}    [WARN] Localhost site referenced!${NORMAL}"
		else
			echo -e "${RED}    [ERROR] Site not reachable!${NORMAL}"
			{
				echo "#>> REPLACE (${SITE})"
				echo "grep -r '${SITE}' . | cut -d ':' -f1 | xargs -I@ sed -i '' -e 's|${SITE}|NEW_URL_TO_REPLACE|g' @"
				echo ""
			} >>"${OUTPUT}"
		fi
	fi
}

function main() {

	if [ -z "${TARGET}" ]; then
		TARGET="CSA"
	fi

	if [ -z "${TARGET_DIR}" ]; then
		[[ "${TARGET}" == "CSA" ]] && TARGET_DIR="${SCRIPT_DIR}/../../conf/CSA"
		[[ "${TARGET}" == "CB" ]] && TARGET_DIR="${SCRIPT_DIR}/../../../../github_cookbooks/content"
	fi

	rm -f "${OUTPUT}"

	if [[ "${TARGET}" == "CSA" ]]; then

		# Check all URL present in the CSA recipes
		COUNT=$(grep -RE "\- uri: [\"]?(http.*)" "${TARGET_DIR}" | tr -d '"' | rev | cut -d' ' -f1 | rev | uniq | sort | wc -l | tr -d ' ')
		echo "[${TARGET}] Validating all unique links (${COUNT}) in the rules within '${TARGET_DIR}'"
		while read -r SITE; do
			check_site "${SITE}"
		done < <(grep -RE "\- uri: [\"]?(http.*)" "${TARGET_DIR}" | tr -d '"' | rev | cut -d' ' -f1 | rev | uniq | sort)

	elif [[ "${TARGET}" == "CB" ]]; then

		# Check all URL present in the cookbooks
		COUNT=$(grep -I -i -r "(http[s]*:.*" "${TARGET_DIR}" | cut -d':' -f 2- | sed 's/.*(\(http[^\)]*\)).*/\1/' | sed 's|[/]*$||g' | cut -d ']' -f 2- | sed 's/^(\(.*\)$/\1/' | grep "^http[s]*://" | sort | uniq | wc -l | tr -d ' ')
		echo "[${TARGET}] Validating all unique links (${COUNT}) in the rules within '${TARGET_DIR}'"

		while read -r SITE; do

			if echo "${SITE}" | grep -q -f "${IGNORED_URLS}"; then
				echo -e "${ORANGE}    [WARN]  Ignoring URL: ${SITE}${NORMAL}"
				{
					echo "#>> IGNORED URL: ${SITE}"
					echo ""
				} >>"${OUTPUT}"
			else
				check_site "${SITE}"
			fi
		done < <(grep -I -i -r "(http[s]*:.*" "${TARGET_DIR}" | cut -d':' -f 2- | sed 's/.*(\(http[^\)]*\)).*/\1/' | sed 's|[/]*$||g' | cut -d ']' -f 2- | sed 's/^(\(.*\)$/\1/' | grep "^http[s]*://" | sort | uniq)

	fi

	CHANGES=0
	if [ -f "${OUTPUT}" ]; then
		CHANGES=$(grep -v "#>> IGNORED URL" "${OUTPUT}" | grep -c '>> ' | tr -d ' ')
	fi

	echo "Done! Recommended changes: ${CHANGES}"

}

main
