# Copyright 2019-2023 VMware, Inc.
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