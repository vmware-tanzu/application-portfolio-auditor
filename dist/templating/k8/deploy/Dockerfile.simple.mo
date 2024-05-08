# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
FROM {{CONTAINER_IMAGE_NAME_NGINX}} AS build
ADD reports.zip /
RUN apk add --no-cache --upgrade bash && \
    apk add unzip && \
    unzip -o /reports.zip -d / && \
    mv /reports/public /public
ADD deploy/container-serve-reports.sh /reports/container-serve-reports.sh

FROM {{CONTAINER_IMAGE_NAME_NGINX}}
RUN apk add --no-cache bash
RUN rm /etc/nginx/conf.d/default.conf
RUN rm -Rf /etc/nginx/public
COPY --from=build /reports /reports
COPY --from=build /public /etc/nginx/public
COPY deploy/container-nginx-rootless.conf /etc/nginx/conf.d/default.conf
RUN sed "s%^pid\s\+[a-z/.]\+;%pid        /tmp/nginx.pid;%" /etc/nginx/nginx.conf > /etc/nginx/nginx-rootless.conf

ENTRYPOINT [ "/reports/container-serve-reports.sh" ]