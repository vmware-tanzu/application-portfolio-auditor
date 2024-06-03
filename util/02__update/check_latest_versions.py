#!/usr/bin/env python
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
"""This scripts automatically checks for updates on the used tools."""

import traceback
import asyncio
import os
import re
import dataclasses
import json
from bs4 import BeautifulSoup
from aiohttp import ClientSession

@dataclasses.dataclass
class Color:
    """Colors used for text output."""
    GREEN = '\033[0;32m'
    RED = '\033[0;31m'
    YELLOW = '\033[0;33m'
    ORANGE = '\033[38;5;208m'
    BOLD = '\033[1m'
    NORMAL = '\033[0m'

# Tool names used to retrieve versions from OS environment variables
tool_names = [ 'BEARER', 'BOOTSTRAP', 'BOOTSTRAP_ICONS', 'CLOC', 'CSA', 'D3', 'DONET_RUNTIME', 'FERNFLOWER', 'FSB',
     'GRYPE', 'HBS', 'INSIDER', 'JQA', 'JQUERY', 'LINGUIST', 'MAI', 'MUSTACHE', 'NIST_MIRROR', 'NGINX', 'OSV', 'OWASP_DC',
    'PMD', 'SCANCODE', 'SLSCAN', 'SYFT', 'TIMELINES_CHART', 'TRIVY', 'WAMT', 'WINDUP' ]

results = {}

async def print_message(message, line_idx, color):
    """Output string as message with color."""
    #line=(f"{line_idx} - {color}{message}{Color.NORMAL}")
    line=(f"{color}{message}{Color.NORMAL}")
    results[line_idx] = line

async def print_ok(message, line_idx=-1):
    """Output string as ok message."""
    await print_message(message, line_idx, Color.GREEN)

async def print_warn(message, line_idx=-1, color=Color.YELLOW):
    """Output string as warning message."""
    await print_message(message, line_idx, color)

async def print_error(message, line_idx=-1):
    """Output string as error message."""
    await print_message(message, line_idx, Color.RED)

def version_key(version):
    """Split the version string into a list of sortable components."""
    components = re.findall(r'\d+|\D+', version)
    return [int(c) if c.isdigit() else c for c in components]

async def fetch_html(client, url):
    """Async fetches a URL."""
    async with client.get(url,allow_redirects=False, timeout=30) as response:
        assert response.status == 200
        return await response.text()

def select_warn_color(project_version, unstable_version):
    """Select warning color based on new version number."""
    return Color.ORANGE if project_version and ('beta' in project_version.lower() or 'rc' in project_version.lower() or (unstable_version and str(project_version) == str(unstable_version))) else Color.YELLOW

async def check_github(client, short_url, regex, name, version, unstable_version, line_idx):
    """Check if the current used version is the latest released one for a GitHub project."""
    url='https://github.com/'+short_url+'/releases/latest'
    prog = re.compile(regex, re.IGNORECASE)
    try:
        response = await client.get(url, allow_redirects=True, timeout=30)
        if response.status == 200:
            response_url = str(response.url)
            project_version = ''
            if response.history:
                match = prog.match(response_url)
                if match:
                    project_version = match.group(1)
                else:
                    await print_error("No version matched ('"+regex+"') in redirected URL: "+response_url,line_idx)
            else:
                await print_error("No redirect to latest release: "+url,line_idx)

            if project_version != version:   
                await print_warn(name+' - New version available: '+str(project_version)+' (current: '+str(version)+') - Download: '+str(response_url),line_idx, select_warn_color(project_version,unstable_version))
            else:
                await print_ok(name+' - Version up-to-date: '+project_version,line_idx)
        else:
            await print_error(f"{name} - Request ({url}) failed with status {response.status}",line_idx)
    except Exception as error:
        print(traceback.format_exc())
        await print_error(f"{name} - Request ({url}) failed: "+repr(error),line_idx)

async def check_github_tag(client, short_url, regex, name, version, unstable_version, line_idx):
    """Check if the current used version is the latest released one foor a GitHub project based on the latest tag."""
    url = f'https://github.com/'+short_url+'/tags'
    try:
        html = await fetch_html(client, url)
        soup = BeautifulSoup(html, "html.parser")

        # Locate the div with class "Box-body p-0"
        div = soup.find('div', class_='Box-body p-0')

        # Find the first <a> tag within this div with matching URL
        link = None
        if div:
            a_tags = div.find_all('a')
            for tag in a_tags:
                href = tag.get('href')
                if href and href.startswith('/'+short_url+'/releases/tag/'):
                    link = href
                    break  # Stop after finding the first matching link
        if link:
            short_link = link.split('/tag/')[1]
            match = re.search(regex, short_link)
            if match:
                project_version = match.group(1)
                if project_version != version:
                    project_href = f'https://github.com'+link
                    await print_warn(f'{name} - New version available: {project_version} (current: {version}) - Download: {project_href}',line_idx, select_warn_color(project_version,unstable_version))
                else:
                    await print_ok(f'{name} - Version up-to-date: {project_version}',line_idx)
            else:
                await print_error(f"{name} - Request ({url}) failed: No matching link found")
        else:
            await print_error(f"{name} - Request ({url}) failed: No link found")

    except Exception as error:
        print(traceback.format_exc())
        await print_error(f"{name} - Request ({url}) failed: "+repr(error),line_idx)

async def check_wamt(client, short_url, regex, name, version, unstable_version, line_idx):
    """Check if the current used WAMT version is the latest released one."""
    prog = re.compile(regex, re.IGNORECASE)
    url=short_url
    try:
        html = await fetch_html(client, url)
        soup = BeautifulSoup(html, "html.parser")
        result = soup.body.findAll(string=prog)
        if result:
            await print_ok(f'{name} - Version up-to-date: {version}',line_idx)
        else:
            download = 'https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/wasdev/downloads/wamt/ApplicationBinaryTP/binaryAppScannerInstaller.jar'
            await print_warn(f'{name} - New version available: {download}',line_idx)
    except Exception as error:
        await print_error(f'{name} - Request ({url}) failed: '+repr(error),line_idx)

async def check_latest_versions(tools):
    """Check if the current tool versions are the latest released ones."""
    async with ClientSession() as client:
        tasks = []
        for i, (check_operation, url, regex, name, version, unstable_version) in enumerate(tools):
            if check_operation == print_bold_message or check_operation == print_ok_message:
                tasks.append(asyncio.create_task(check_operation(name,i+1)))
            else:
                tasks.append(asyncio.create_task(check_operation(client, url, regex, name, version, unstable_version, i+1)))
        await asyncio.gather(*tasks)

async def check_dotnet_runtime(client, short_url, regex, name, version, unstable_version, line_idx):
    """Check if the current used version is the latest released one."""
    # Python equivalent of the following line:
    # curl -fsSL 'https://mcr.microsoft.com/v2/dotnet/runtime/tags/list' |grep 'alpine'| grep -v 'preview' | grep -v 'amd64'|grep -v 'arm' |sort|tail -1|tr -d ' ,"'
    url = f'https://mcr.microsoft.com/v2/dotnet/runtime/tags/list'
    try:
        html = await fetch_html(client, url)
        tags = json.loads(html)['tags']
        filtered_tags = [tag for tag in tags if 'alpine' in tag and 'preview' not in tag and 'amd64' not in tag and 'arm' not in tag and 'rc' not in tag]
        filtered_tags.sort()
        project_version = filtered_tags[-1] if filtered_tags else None
        if project_version != version:
            await print_warn(f'{name} - New version available: {project_version} (current: {version}) - Check: {url}',line_idx, select_warn_color(project_version,unstable_version))
        else:
            await print_ok(f'{name} - Version up-to-date: {project_version}',line_idx)
    except Exception as error:
        await print_error(f'{name} - Request ({url}) failed: '+repr(error),line_idx)

async def check_fernflower(client, short_url, regex, name, version, unstable_version, line_idx):
    """Check if the current used version is the latest released one."""
    # Python equivalent of the following line:
    url='https://github.com/JetBrains/intellij-community'
    try:
        project_version=os.popen('git ls-remote --tags "'+url+'.git" refs/tags/idea/\\*| tr -d \'^{}\' | cut -d "/" -f 4- |sort -t. -k1,1n -k2,2n -k3,3n -u -r |tail -n 1').read().strip()
        if project_version != version:
            await print_warn(f'{name} - New version available: {project_version} (current: {version}) - Check: {url}',line_idx, select_warn_color(project_version,unstable_version))
        else:
            await print_ok(f'{name} - Version up-to-date: {project_version}',line_idx)
    except Exception as error:
        await print_error(f'{name} - Request ({url}) failed: '+repr(error),line_idx)


async def print_bold_message(message,line_idx):
    # Section for the supporting frameworks
   await print_message(message,line_idx,Color.BOLD)

async def print_ok_message(message,line_idx):
   await print_ok(message,line_idx)


if __name__ == '__main__':

    # Load all versions from environment variables
    for tool_name in tool_names:
        globals()[f'{tool_name}_VERSION'] = os.getenv(f'{tool_name}_VERSION')

    # Check updates asynchronously
    asyncio.run(check_latest_versions([
        # Section for application analysis tools
        (print_bold_message, '', r'', 'Application Analysis Tools', '', None),
        (check_github, 'pmd/pmd', r'.*pmd_releases/(.+)', 'PMD', PMD_VERSION, None),
        ## OWASP DC 9.x requires major changes before updating
        (check_github, 'jeremylong/DependencyCheck', r'.*/tag/v(.+)', 'OWASP DC', OWASP_DC_VERSION, '9.1.0'),
        ## Find Security Bugs' latest version does not provide a pre-built CLI binary yet
        (check_github, 'find-sec-bugs/find-sec-bugs', r'.*/tag/version-(.+)', 'Find Security Bugs', FSB_VERSION, '1.13.0'),
        (check_github, 'nexB/scancode-toolkit', r'.*/tag/v(.+)', 'ScanCode', SCANCODE_VERSION, None),
        (check_github, 'AlDanial/cloc', r'.*/tag/v(.+)', 'CLOC', CLOC_VERSION, None),
        ## Windup: Versions from 6.2.x do not allow multiple targets
        (check_github, 'windup/windup-distribution', r'.*/tag/(.+).Final', 'Windup', WINDUP_VERSION, '6.3.7'),
        (check_github, 'vmware-tanzu/cloud-suitability-analyzer', r'.*/tag/v(.+)', 'CSA', CSA_VERSION, None),
        (check_github, 'microsoft/ApplicationInspector', r'.*/tag/v(.+)', 'MAI', MAI_VERSION, None),
        (check_github, 'github/linguist', r'.*/tag/v(.+)', 'Linguist', LINGUIST_VERSION, None),
        (check_github, 'insidersec/insider', r'.*tag/(.+)', 'Insider', INSIDER_VERSION, None),
        (check_github, 'ShiftLeftSecurity/sast-scan', r'.*/tag/v(.+)', 'SLSCan', SLSCAN_VERSION, None),
        (check_github, 'anchore/grype', r'.*tag/v(.+)', 'Grype', GRYPE_VERSION, None),
        (check_github, 'anchore/syft', r'.*tag/v(.+)', 'Syft', SYFT_VERSION, None),
        (check_github, 'aquasecurity/trivy', r'.*tag/v(.+)', 'Trivy', TRIVY_VERSION, None),
        (check_github, 'google/osv-scanner', r'.*tag/v(.+)', 'OSV', OSV_VERSION, None),
        (check_wamt, 'https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/wasdev/downloads/wamt/ApplicationBinaryTP/', r'.*(2024-03-01).*(09:03).*', 'IBM WAMT', WAMT_VERSION, None),
        (check_github, 'bearer/bearer', r'.*tag/v(.+)', 'Bearer', BEARER_VERSION, None),

        # Section for the supporting frameworks
        (print_bold_message, '', r'', '\nSupporting frameworks', '', None),
        (check_fernflower, '', r'', 'Fernflower', FERNFLOWER_VERSION, None),
        (check_github_tag,'tests-always-included/mo', r'(.+)', 'Mustache', MUSTACHE_VERSION, None),
        (check_github_tag, 'sunng87/handlebars-rust', r'v(.+)', 'Handlebars', HBS_VERSION, None),
        # NIST Data Mirror - end-of-life and unlikely to change
        (print_ok_message, '', r'', f'NIST Data Mirror - Version up-to-date: {NIST_MIRROR_VERSION}', '', None),
        # D3.js - Download from: https://cdn.jsdelivr.net/npm/d3@7.8.2/dist/d3.min.js
        (check_github, 'd3/d3', r'.*tag/v(.+)','D3.js', D3_VERSION, None),
        (check_github, 'jquery/jquery', r'.*tag/(.+)', 'jQuery', JQUERY_VERSION, None),
        (check_github, 'twbs/bootstrap', r'.*tag/v(.+)','Bootstrap', BOOTSTRAP_VERSION, None),
        (check_github, 'twbs/icons', r'.*tag/v(.+)','Bootstrap Icons', BOOTSTRAP_ICONS_VERSION, None),
        (check_github_tag,'nginx/nginx', r'release-(.+)', 'Nginx', NGINX_VERSION, None),
        (check_github_tag,'vasturiano/timelines-chart', r'v(.+)', 'Timeline Chart', TIMELINES_CHART_VERSION, None),
        (check_dotnet_runtime, '', r'', '.NET Runtime', DONET_RUNTIME_VERSION, None)
    ]))

    for line_idx, result in sorted(results.items()):
        print(result)

    print(f"\n{Color.GREEN}Green entries{Color.NORMAL} are up-to-date. {Color.ORANGE}Orange ones{Color.NORMAL} highlight new unappropriate available versions. {Color.YELLOW}Yellow ones{Color.NORMAL} reflect new versions to consider.{Color.NORMAL}")
    print(f"Edit manually versions in '{Color.BOLD}_versions.sh{Color.NORMAL}' and run '{Color.BOLD}./audit update{Color.NORMAL}' to download and update your install to the desired versions.{Color.NORMAL}")