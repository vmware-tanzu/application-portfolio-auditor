# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
ARG IMG_BUILD
ARG IMG_BASE
#ARG IMG_SHELL

FROM ${IMG_BUILD} as build
ARG CSA_VERSION
RUN apk add --no-cache --upgrade bash && apk add curl
WORKDIR /tool
RUN curl  -o csa -L https://github.com/vmware-tanzu/cloud-suitability-analyzer/releases/download/v${CSA_VERSION}/csa-l
RUN chmod +x csa

#FROM ${IMG_SHELL} as shell

FROM ${IMG_BASE}
ARG IMG_BUSYBOX
WORKDIR /tool
#COPY --from=shell /bin/sh /bin/sh
COPY --from=build /tool/csa csa
ENTRYPOINT [ "./csa" ]
