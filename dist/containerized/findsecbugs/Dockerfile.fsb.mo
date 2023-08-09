# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
FROM alpine:latest AS build
ADD findsecbugs-cli-{{FSB_VERSION}}.zip /
RUN apk add --no-cache --upgrade bash && \
    apk add unzip sed && \
    unzip -o /findsecbugs-cli-{{FSB_VERSION}}.zip -d /

FROM eclipse-temurin:11-jre
COPY --from=build /findsecbugs-cli /findsecbugs-cli
ENTRYPOINT [ "/findsecbugs-cli/findsecbugs.sh" ]
