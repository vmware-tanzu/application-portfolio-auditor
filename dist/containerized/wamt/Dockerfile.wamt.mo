# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
FROM alpine:latest AS build
ADD wamt-{{WAMT_VERSION}}.zip /
RUN apk add --no-cache --upgrade bash && \
    apk add unzip sed && \
    unzip -o /wamt-{{WAMT_VERSION}}.zip -d /

FROM {{IMG_ECLIPSE_TEMURIN_21}}-alpine
COPY --from=build /wamt /wamt
ENTRYPOINT [ "java", "-Duser.language=en", "-jar", "/wamt/binaryAppScanner.jar" ]
