# Copyright 2019-2023 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
ARG NGINX_VERSION={{NGINX_VERSION}}

FROM nginx:${NGINX_VERSION}-alpine AS build
ADD reports.zip /
RUN apk add --no-cache --upgrade bash && \
    apk add unzip && \
    unzip -o /reports.zip -d / && \
    mv /reports/public /public

FROM nginx:${NGINX_VERSION}-alpine
RUN rm /etc/nginx/conf.d/default.conf
RUN rm -Rf /etc/nginx/public
COPY --from=build /public /etc/nginx/public
COPY deploy/docker-nginx.conf /etc/nginx/conf.d/default.conf
