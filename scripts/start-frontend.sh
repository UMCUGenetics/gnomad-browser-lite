#!/usr/bin/env bash
# Start the Vite dev server
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Load environment if available
if [[ -f .env ]]; then
    . ./.env
fi

PORT="${PORT:-3000}"
VITE_PORT="${VITE_PORT:-5173}"
# Follow the backend port automatically unless VITE_API_URL is set explicitly
# (e.g. backend on another host/port).
VITE_API_URL="${VITE_API_URL:-http://localhost:$PORT}"

echo "Starting frontend on http://localhost:$VITE_PORT"
echo "  API URL: $VITE_API_URL"
cd frontend && VITE_PORT="$VITE_PORT" VITE_API_URL="$VITE_API_URL" pnpm dev
