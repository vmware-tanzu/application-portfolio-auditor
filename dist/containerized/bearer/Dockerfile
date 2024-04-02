# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
ARG IMG_BUILD
ARG IMG_BASE

FROM ${IMG_BUILD} as build
ARG BEARER_VERSION
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y ca-certificates software-properties-common golang git
RUN git clone --branch "v${BEARER_VERSION}" "https://github.com/Bearer/bearer.git" /tool/bearer
WORKDIR /tool/bearer
RUN go clean -modcache && go mod download
RUN go build -a -o ../bearer-comparison/base-bearer ./cmd/bearer/bearer.go || go build -a -o ../bearer-comparison/base-bearer ./cmd/bearer/main.go
RUN mv /tool/bearer-comparison/base-bearer /tool/bearer/bearer

FROM ${IMG_BASE}
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y git && \
    apt-get clean && \
    apt-get purge -y --auto-remove && \
    apt remove apt --autoremove -y --allow-remove-essential && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    useradd --system --user-group --create-home runuser
COPY --from=build /tool/bearer/bearer /usr/local/bin/
USER runuser
RUN git config --global --add safe.directory '*'
ENTRYPOINT ["bearer"]
