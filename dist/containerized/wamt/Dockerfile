# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
ARG IMG_BASE
ARG IMG_JAVA

FROM ${IMG_BASE} AS build
ARG WAMT_VERSION
ADD wamt-${WAMT_VERSION}.zip /
RUN apk add --no-cache --upgrade bash && \
    apk add unzip sed && \
    unzip -o /wamt-${WAMT_VERSION}.zip -d /

FROM ${IMG_JAVA}
COPY --from=build /wamt /wamt
ENTRYPOINT [ "java", "-Duser.language=en", "-jar", "/wamt/binaryAppScanner.jar" ]
