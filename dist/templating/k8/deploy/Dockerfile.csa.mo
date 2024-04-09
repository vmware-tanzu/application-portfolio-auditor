# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
FROM {{CONTAINER_IMAGE_NAME_NGINX}} AS build
ARG ARCH
ADD reports.zip /
RUN apk add --no-cache --upgrade bash && \
    apk add unzip && \
    unzip -o /reports.zip -d / && \
    mv /reports/public /public
ADD deploy/container-serve-reports.sh /reports/container-serve-reports.sh
ADD deploy/csa-l_${ARCH} /reports/csa-l

FROM {{CONTAINER_IMAGE_NAME_NGINX}}
RUN apk add --no-cache bash
RUN rm /etc/nginx/conf.d/default.conf
RUN rm -Rf /etc/nginx/public
COPY --from=build /reports /reports
COPY --from=build /public /etc/nginx/public
COPY deploy/container-nginx.conf /etc/nginx/conf.d/default.conf

ENTRYPOINT [ "/reports/container-serve-reports.sh" ]