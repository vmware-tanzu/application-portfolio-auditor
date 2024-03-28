# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
ARG IMG_BASE
ARG IMG_DOTNET_RUNTIME

FROM ${IMG_BASE} AS build
ARG MAI_VERSION
ADD ApplicationInspector_netcoreapp_${MAI_VERSION}.zip /
RUN apk add --no-cache --upgrade bash && \
    apk add unzip sed && \
    unzip -o /ApplicationInspector_netcoreapp_${MAI_VERSION}.zip -d / && \
    mv /ApplicationInspector_netcoreapp_${MAI_VERSION} /mai
ADD mai.sh /mai/mai.sh

FROM ${IMG_DOTNET_RUNTIME}
COPY --from=build /mai /mai
ENTRYPOINT [ "/mai/mai.sh" ]

# check https://github.com/dotnet/dotnet-docker/issues/2074