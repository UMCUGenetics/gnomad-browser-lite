# gnomad-bench shared API image — the Rust VariantBackend server (this crate).
#
# Built via Cloud Build from a STAGED, hermetic context that contains this crate
# plus the genohype workspace it `path`-depends on (core/cli/pool/mcp), so the
# path deps resolve with no git auth and no Cargo.toml changes. The staging is
# assembled by gnomad-bench/scripts/build-api-image.sh; the context layout is:
#
#   genohype/{Cargo.toml,Cargo.lock,core,cli,pool,mcp}   # workspace, no target/
#   gnomad-browser-lite/backend/                          # this crate, no target/
#
# Zero-config default backend = hail-gcs over public gnomAD GCS, so the image runs
# end-to-end with no config file (the lean-smoke first signal). Other arms are
# selected at runtime with `backend --config <arm>.toml`.

FROM rust:1.91-slim-bookworm@sha256:8514999d4786ef12efe89239e86b3d0a021b94b9d35108c8efe6c79ca7dc1a65 AS builder

# maak builder packages beschikbaar voor we installen
COPY backend/builder-packages.lock \
     /tmp/builder-packages.lock

# Build deps: DuckDB `bundled` compiles the amalgamation (cc/cmake) and its
# bindings use clang/libclang; openssl-sys (pulled transitively) needs
# pkg-config + libssl. All builder-stage only — the runtime image stays slim.
RUN apt-get update \
    && grep -Ev '^[[:space:]]*(#|$)' /tmp/builder-packages.lock \
       | xargs apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /tmp/builder-packages.lock

WORKDIR /src

COPY backend/dependencies/genohype /src/genohype
COPY backend /src/gnomad-browser-lite/backend
# fastVEP: only its manifests are read (the `vep` feature is off so nothing here
# compiles); present so cargo can resolve genohype-core/cli's optional path deps.
COPY backend/dependencies/fastVEP /src/fastVEP

WORKDIR /src/gnomad-browser-lite/backend
# `bundled` = self-contained DuckDB (no system libduckdb needed at runtime).
RUN cargo build --release --locked --features bundled

# ---------------------------------------------------------------------------
FROM debian:bookworm-slim@sha256:99c0b25c46d0214d5a2091092e7908907dcaecd6a962cde0ac700acee222b6f3 AS runtime

# maak runtime packages beschikbaar
COPY backend/runtime-packages.lock \
     /tmp/runtime-packages.lock

RUN apt-get update \
    && grep -Ev '^[[:space:]]*(#|$)' /tmp/runtime-packages.lock \
       | xargs apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /tmp/runtime-packages.lock

RUN useradd -r -s /usr/sbin/nologin bench

COPY --from=builder \
    /src/gnomad-browser-lite/backend/target/release/backend \
    /usr/local/bin/backend

USER bench
ENV RUST_LOG=info
# The server resolves its listen port from $PORT (Cloud Run overrides this to
# match container_port; see infra/main.tf api_port).
ENV PORT=8000
EXPOSE 8000

# No subcommand = serve. Default config (no file) = hail-gcs over public GCS.
ENTRYPOINT ["usr/local/bin/backend"]
CMD []
