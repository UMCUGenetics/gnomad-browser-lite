# syntax=docker/dockerfile:1.7

# ---------------------------------------------------------------------------
# Builder
# ---------------------------------------------------------------------------

FROM node:22.21.1-bookworm-slim AS builder

ENV PNPM_HOME=/pnpm
ENV PATH="${PNPM_HOME}:${PATH}"

RUN corepack enable

WORKDIR /app

# Dependencybestanden eerst kopiëren, zodat deze laag hergebruikt kan worden
# wanneer alleen frontendbroncode verandert.
COPY package.json pnpm-lock.yaml ./
COPY frontend/package.json ./frontend/package.json

RUN pnpm install --frozen-lockfile

# Frontendbroncode kopiëren en een production-build maken.
COPY frontend ./frontend

RUN pnpm --dir frontend build


# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------

FROM nginx:1.29.2-alpine AS runtime

COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=builder \
    /app/frontend/dist \
    /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
