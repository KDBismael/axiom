#!/usr/bin/env bash
# Builds a signed release IPA pointed at the production backend.
# Run this instead of archiving from Xcode directly — Xcode Archive reuses
# whatever --dart-define values were last written to
# ios/Flutter/Generated.xcconfig, which is almost always your local dev
# config, not prod.
#
# Also bumps pubspec.yaml's build number on every run (App Store rejects a
# re-upload of a build number it's already seen). Pass a version name to
# also update it, e.g.: ./scripts/build_prod_ipa.sh 1.0.1
set -euo pipefail

cd "$(dirname "$0")/.."

new_version=$("$(dirname "$0")/bump_version.sh" "${1:-}")
echo "Building version ${new_version}..."

build_started=$(mktemp)
trap 'rm -f "$build_started"' EXIT

flutter build ipa \
  --dart-define-from-file=config/production.json

ipa=$(find build/ios/ipa -maxdepth 1 -type f -name '*.ipa' -newer "$build_started" -print -quit 2>/dev/null || true)
if [[ -z "$ipa" ]]; then
  echo "Échec de l'export IPA : aucun nouvel IPA créé. Vérifiez les accords Apple Developer et la signature de distribution." >&2
  exit 1
fi

echo ""
echo "IPA ready at $ipa — upload via Transporter or:"
echo "  xcrun altool --upload-app --type ios -f '$ipa' --apiKey <key> --apiIssuer <issuer>"
