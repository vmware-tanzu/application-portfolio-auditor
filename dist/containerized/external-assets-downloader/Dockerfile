# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0
FROM node:21-alpine AS base
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
COPY . /app
WORKDIR /app
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
CMD [ "pnpm", "run", "prebuild" ]
