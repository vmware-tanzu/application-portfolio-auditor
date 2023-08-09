# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
FROM aquasec/trivy:{{TRIVY_VERSION}}

RUN trivy image --download-db-only --no-progress
RUN trivy image --download-java-db-only --no-progress

VOLUME ["/out", "/src"]

ENTRYPOINT ["trivy"]
