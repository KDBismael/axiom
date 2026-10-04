#!/usr/bin/env bash
# Builds an installable release APK against the development backend.
set -euo pipefail

cd "$(dirname "$0")/.."

flutter build apk \
  --release \
  --dart-define-from-file=config/development.json \
  "$@"

echo ""
echo "APK de développement : build/app/outputs/flutter-apk/app-release.apk"
