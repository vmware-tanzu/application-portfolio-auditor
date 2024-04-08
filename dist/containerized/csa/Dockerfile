# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
ARG IMG_BUILD
ARG IMG_BASE

FROM ${IMG_BUILD} as build
ARG CSA_VERSION
ARG ARCH
# Install prerequisites
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y ca-certificates software-properties-common golang-go go-bindata git nodejs npm musl-tools gcc-mingw-w64 build-essential coreutils
# Install goreleaser
RUN echo 'deb [trusted=yes] https://repo.goreleaser.com/apt/ /' | tee /etc/apt/sources.list.d/goreleaser.list
RUN apt update && \
    apt-get install -y goreleaser
# Clone selected branch
RUN git clone --branch "v${CSA_VERSION}" "https://github.com/vmware-tanzu/cloud-suitability-analyzer.git" /tool/csa
WORKDIR /tool/csa
# Add arm64 build for Linux
RUN sed -i '117s/$/\n      - arm64/' ./csa-app/.goreleaser.yaml
# Disable windows binary and funding information to speedup build
RUN sed -i 's/--id='\''windows'\''//g' ./build.sh && sed -i 's/&& npm fund //g' ./build.sh
# Build CSA
RUN ./build.sh
RUN mv /tool/csa/csa-app/dist/csa-linux-${ARCH} /tool/csa-l

FROM ${IMG_BASE}
ARG IMG_BUSYBOX
WORKDIR /tool
COPY --from=build /tool/csa-l csa
ENTRYPOINT [ "./csa" ]
