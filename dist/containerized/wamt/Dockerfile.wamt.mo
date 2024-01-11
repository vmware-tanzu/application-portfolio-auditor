# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
FROM alpine:latest AS build
ADD wamt-{{WAMT_VERSION}}.zip /
RUN apk add --no-cache --upgrade bash && \
    apk add unzip sed && \
    unzip -o /wamt-{{WAMT_VERSION}}.zip -d /

FROM eclipse-temurin:20-jre
COPY --from=build /wamt /wamt
ENTRYPOINT [ "java", "-Duser.language=en", "-jar", "/wamt/binaryAppScanner.jar" ]
