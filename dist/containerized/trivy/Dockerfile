# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
ARG TRIVY_VERSION

FROM aquasec/trivy:${TRIVY_VERSION}

RUN trivy image --download-db-only --no-progress
RUN trivy image --download-java-db-only --no-progress

VOLUME ["/out", "/src"]

ENTRYPOINT ["trivy"]
