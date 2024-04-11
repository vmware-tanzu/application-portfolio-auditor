# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
FROM {{CONTAINER_IMAGE_NAME_NGINX}} AS build
ADD reports.zip /
RUN apk add --no-cache --upgrade bash && \
    apk add unzip && \
    unzip -o /reports.zip -d / && \
    mv /reports/public /public

FROM {{CONTAINER_IMAGE_NAME_NGINX}}
RUN rm /etc/nginx/conf.d/default.conf
RUN rm -Rf /etc/nginx/public
COPY --from=build /public /etc/nginx/public
COPY deploy/container-nginx.conf /etc/nginx/conf.d/default.conf
