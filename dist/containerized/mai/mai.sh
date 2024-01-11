#!/bin/sh
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

cd mai
dotnet '/mai/ApplicationInspector.CLI.dll' "$@"

# Copy results to "/out" directory
if [ -d "/out" ]; then
    cd /out
    cp -Rf "/mai/html" .
    cp "/mai/output.html" .
fi
