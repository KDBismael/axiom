#!/usr/bin/env bash
# Builds a development-signed IPA against the development backend.
# The selected Apple team must have a development provisioning profile for
# the existing Runner bundle identifier.
set -euo pipefail

cd "$(dirname "$0")/.."

build_started=$(mktemp)
trap 'rm -f "$build_started"' EXIT

flutter build ipa \
  --export-method development \
  --dart-define-from-file=config/development.json \
  "$@"

ipa=$(find build/ios/ipa -maxdepth 1 -type f -name '*.ipa' -newer "$build_started" -print -quit 2>/dev/null || true)
if [[ -z "$ipa" ]]; then
  echo "Échec de l'export IPA : aucun nouvel IPA créé. Vérifiez la signature de développement." >&2
  exit 1
fi

echo ""
echo "IPA de développement : $ipa"
