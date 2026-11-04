# syntax=docker/dockerfile:1.7

# =============================================================================
# Stage 1: buildomgeving
#
# Deze stage bouwt achtereenvolgens:
#   1. @genohype/assistant-ui met npm workspaces
#   2. gnomAD Browser Lite frontend met pnpm
# =============================================================================

FROM node:22.21.1-bookworm-slim AS builder

# frontend/pnpm-lock.yaml heeft lockfileVersion 6.0 en hoort bij pnpm 8.
RUN npm install --global pnpm@8.15.9 \
    && test "$(pnpm --version)" = "8.15.9"

WORKDIR /app


# =============================================================================
# Deel A: bouw @genohype/assistant-ui
#
# shared/genohype/ui/package.json definieert:
#
#   "workspaces": [
#     "packages/*"
#   ]
#
# Daarom installeren en bouwen we assistant-ui vanaf de Genohype UI-root
# met npm workspacecommando's.
# =============================================================================

# Kopieer eerst alleen de manifests. Hierdoor kan Docker deze installatielaag
# hergebruiken zolang de packagebestanden niet veranderen.
COPY shared/genohype/ui/package.json \
     /app/genohype/ui/package.json

COPY shared/genohype/ui/packages/assistant-ui/package.json \
     /app/genohype/ui/packages/assistant-ui/package.json

WORKDIR /app/genohype/ui

# Installeer alleen de assistant-ui workspace en diens ontwikkeldependencies.
#
# Let op: Genohype UI heeft momenteel geen package-lock.json. Deze stap is
# daarom nog niet volledig gelockt.
RUN npm install \
      --workspace=@genohype/assistant-ui \
      --include-workspace-root=false

# Kopieer daarna de broncode van assistant-ui.
COPY shared/genohype/ui/packages/assistant-ui/ \
     /app/genohype/ui/packages/assistant-ui/

# Bouw assistant-ui vanuit de npm-workspace.
#
# Verwachte output:
#   packages/assistant-ui/dist/index.js
#   packages/assistant-ui/dist/index.d.ts
RUN npm run build --workspace=@genohype/assistant-ui \
    && test -f packages/assistant-ui/dist/index.js \
    && test -f packages/assistant-ui/dist/index.d.ts


# =============================================================================
# Deel B: bouw gnomAD Browser Lite frontend
#
# De containerlayout is bewust:
#
#   /app/
#   ├── genohype/
#   │   └── ui/packages/assistant-ui/
#   └── gnomad-browser-lite/
#       └── frontend/
#
# Daardoor blijft deze dependency geldig:
#
#   file:../../genohype/ui/packages/assistant-ui
# =============================================================================

# Kopieer eerst het frontendmanifest en de bestaande pnpm-lockfile.
COPY frontend/package.json \
     frontend/pnpm-lock.yaml \
     /app/gnomad-browser-lite/frontend/

WORKDIR /app/gnomad-browser-lite/frontend

# Installeer uitsluitend de versies uit frontend/pnpm-lock.yaml.
# assistant-ui is in Deel A al gebouwd.
RUN pnpm install --frozen-lockfile

# Kopieer daarna pas de overige frontendbroncode.
COPY frontend/ \
     /app/gnomad-browser-lite/frontend/

# VITE_API_URL is baked into the bundle at build time (import.meta.env.VITE_API_URL,
# read in frontend/src/api/client.ts). Supplied via compose build.args; when empty,
# client.ts falls back to http://localhost:3000.
ARG VITE_API_URL
ENV VITE_API_URL=${VITE_API_URL}

# Build the existing frontend without changing its implementation.
# Vite transpiles TypeScript but does not run the separate tsc typecheck.
RUN pnpm exec vite build

# =============================================================================
# Stage 2: minimale Nginx-runtime
#
# Het uiteindelijke image bevat geen Node.js, npm, pnpm, TypeScriptbroncode
# of Genohypebroncode. Alleen Nginx en de gebouwde statische website.
# =============================================================================

FROM nginx:1.29.2-alpine AS runtime

COPY frontend/nginx.conf \
     /etc/nginx/conf.d/default.conf

COPY --from=builder \
     /app/gnomad-browser-lite/frontend/dist \
     /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
