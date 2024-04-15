#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
/reports/csa-l ui --database-dir=/reports --port=3001 &
nginx -c /etc/nginx/nginx-rootless.conf -g "daemon off;"
