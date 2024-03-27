# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
FROM alpine:latest AS build
ADD pmd-bin-{{PMD_VERSION}}.zip /
RUN apk add --no-cache --upgrade bash && \
    apk add unzip sed && \
    unzip -o /pmd-bin-{{PMD_VERSION}}.zip -d /

FROM {{IMG_ECLIPSE_TEMURIN_21}}
RUN apt-get update && apt-get upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
COPY --from=build /pmd-bin-{{PMD_VERSION}} /pmd
ENTRYPOINT [ "/pmd/bin/pmd" ]
