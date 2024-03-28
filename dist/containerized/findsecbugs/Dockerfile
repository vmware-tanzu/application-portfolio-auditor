# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
ARG IMG_BASE
ARG IMG_JAVA

FROM ${IMG_BASE} AS build
ARG FSB_VERSION
ADD findsecbugs-cli-${FSB_VERSION}.zip /
RUN apk add --no-cache --upgrade bash && \
    apk add unzip sed && \
    unzip -o /findsecbugs-cli-${FSB_VERSION}.zip -d /

FROM ${IMG_JAVA}
COPY --from=build /findsecbugs-cli /findsecbugs-cli
ENTRYPOINT [ "/findsecbugs-cli/findsecbugs.sh" ]
