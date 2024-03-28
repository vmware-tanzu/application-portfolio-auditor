# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
ARG IMG_BASE

FROM ${IMG_BASE}
ARG CLOC_VERSION

RUN apk update && \
    apk upgrade && \
    apk add perl && \
    rm -rf /var/cache/apk/* 

# Note: This automatically unpacks the tar.gz file.
ADD cloc-${CLOC_VERSION}.tar.gz /tool
WORKDIR /tool/cloc-${CLOC_VERSION}

ENTRYPOINT [ "./cloc" ]