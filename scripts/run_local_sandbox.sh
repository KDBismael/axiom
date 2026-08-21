#!/usr/bin/env bash
# Runs the app against a local/sandbox backend with Genius Pay pay-ins enabled.
# Override API_BASE_URL for a physical device, for example:
# API_BASE_URL=http://192.168.1.20:3000 ./scripts/run_local_sandbox.sh
set -euo pipefail

cd "$(dirname "$0")/.."

api_base_url="${API_BASE_URL:-http://localhost:3000}"

flutter run \
  --dart-define="API_BASE_URL=${api_base_url}" \
  --dart-define=AXIOM_PAYINS_ENABLED=true \
  --dart-define=AXIOM_PAYMENT_ENV=sandbox \
  --dart-define=AXIOM_GENIUSPAY_SANDBOX_VERIFIED=true \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=535813765420-ues8l2u03hs7385qhcvp93teu4fceq9a.apps.googleusercontent.com \
  "$@"
