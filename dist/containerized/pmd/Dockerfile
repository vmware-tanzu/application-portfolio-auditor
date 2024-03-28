# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
ARG IMG_BASE
ARG IMG_JAVA

FROM ${IMG_BASE} AS build
ARG PMD_VERSION
ADD pmd-bin-${PMD_VERSION}.zip /
RUN apk add --no-cache --upgrade bash && \
    apk add unzip sed && \
    unzip -o /pmd-bin-${PMD_VERSION}.zip -d /

FROM ${IMG_JAVA}
ARG PMD_VERSION
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    apt remove apt --autoremove -y --allow-remove-essential && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
COPY --from=build /pmd-bin-${PMD_VERSION} /pmd
ENTRYPOINT [ "/pmd/bin/pmd" ]
