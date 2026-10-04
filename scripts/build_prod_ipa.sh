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

flutter build ipa \
  --dart-define-from-file=config/production.json

echo ""
echo "IPA ready at build/ios/ipa/*.ipa — upload via Transporter or:"
echo "  xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa --apiKey <key> --apiIssuer <issuer>"
