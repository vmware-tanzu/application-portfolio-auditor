# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
applications:
- name: {{CF_APP_NAME}}
  disk_quota: 2G
  instances: 1
  memory: 2G
  buildpacks:
#  - nginx_buildpack
#  - https://github.com/cloudfoundry/nginx-buildpack.git
  - {{NGINX_BUILDPACK}}
  stack: cflinuxfs3
  sidecars:
  - name: csa
    process_types:
    - web
    command: './csa/csa-l ui --database-dir=./csa --port=3001'
