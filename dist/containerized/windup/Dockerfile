# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
ARG IMG_BASE
ARG IMG_JAVA

FROM ${IMG_BASE} AS build
ARG WINDUP_VERSION
ADD windup-cli-${WINDUP_VERSION}.Final-offline.zip /
ADD windup-cli-append /windup-cli-append
RUN apk add --no-cache --upgrade bash && \
    apk add unzip sed && \
    unzip -o /windup-cli-${WINDUP_VERSION}.Final-offline.zip -d / && \
    mv /windup-cli-${WINDUP_VERSION}.Final /windup && \
    sed -i '/MAX_METASPACE_SIZE"/,$d' /windup/bin/windup-cli && \
    cat /windup-cli-append >> /windup/bin/windup-cli

FROM ${IMG_JAVA}
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    apt remove apt --autoremove -y --allow-remove-essential && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
COPY --from=build /windup /windup
ENTRYPOINT [ "/windup/bin/windup-cli" ]
