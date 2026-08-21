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
  --dart-define=API_BASE_URL=https://server.ndeli.tech \
  --dart-define=AXIOM_PAYINS_ENABLED=false \
  --dart-define=AXIOM_PAYMENT_ENV=disabled \
  --dart-define=AXIOM_GENIUSPAY_SANDBOX_VERIFIED=false \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=535813765420-ues8l2u03hs7385qhcvp93teu4fceq9a.apps.googleusercontent.com

echo ""
echo "IPA ready at build/ios/ipa/*.ipa — upload via Transporter or:"
echo "  xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa --apiKey <key> --apiIssuer <issuer>"
