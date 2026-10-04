#!/usr/bin/env bash
# Runs the Flutter app against the deployed development backend.
set -euo pipefail

cd "$(dirname "$0")/.."

flutter run \
  --dart-define-from-file=config/development.json \
  "$@"
