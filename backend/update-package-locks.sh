#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BUILDER_IMAGE="${BUILDER_IMAGE:-rust:1.91-slim-bookworm}"
RUNTIME_IMAGE="${RUNTIME_IMAGE:-debian:bookworm-slim}"

BUILDER_LOCK="${SCRIPT_DIR}/builder-packages.lock"
RUNTIME_LOCK="${SCRIPT_DIR}/runtime-packages.lock"

update_lock() {
    local image="$1"
    local lock_file="$2"
    local temp_file

    temp_file="$(mktemp)"
    trap 'rm -f "${temp_file}"' RETURN

    docker run --rm \
        --entrypoint bash \
        --volume "${lock_file}:/tmp/packages.lock:ro" \
        "${image}" \
        -euo pipefail -c '
            apt-get update >/dev/null

            while IFS= read -r line || [[ -n "${line}" ]]; do
                line="${line%%#*}"
                line="$(printf "%s" "${line}" | xargs)"

                [[ -z "${line}" ]] && continue

                package="${line%%=*}"

                version="$(
                    apt-cache policy "${package}" |
                    awk "/Candidate:/ { print \$2; exit }"
                )"

                if [[ -z "${version}" || "${version}" == "(none)" ]]; then
                    echo "Geen versie gevonden voor ${package}" >&2
                    exit 1
                fi

                printf "%s=%s\n" "${package}" "${version}"
            done < /tmp/packages.lock
        ' > "${temp_file}"

    if [[ ! -s "${temp_file}" ]]; then
        echo "Fout: gegenereerde lockfile is leeg: ${lock_file}" >&2
        exit 1
    fi

    mv "${temp_file}" "${lock_file}"
    trap - RETURN
}

echo "Builderpackages bijwerken..."
update_lock "${BUILDER_IMAGE}" "${BUILDER_LOCK}"

echo "Runtimepackages bijwerken..."
update_lock "${RUNTIME_IMAGE}" "${RUNTIME_LOCK}"

echo
echo "Bijgewerkte builderpackages:"
cat "${BUILDER_LOCK}"

echo
echo "Bijgewerkte runtimepackages:"
cat "${RUNTIME_LOCK}"

echo
echo "Controleer de wijzigingen met:"
echo "  git diff -- backend/builder-packages.lock backend/runtime-packages.lock"
