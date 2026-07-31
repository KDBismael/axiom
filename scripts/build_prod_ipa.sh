#!/usr/bin/env bash
# Builds a signed release IPA pointed at the production backend.
# Run this instead of archiving from Xcode directly — Xcode Archive reuses
# whatever --dart-define values were last written to
# ios/Flutter/Generated.xcconfig, which is almost always your local dev
# config, not prod.
set -euo pipefail

cd "$(dirname "$0")/.."

flutter build ipa \
  --dart-define=API_BASE_URL=http://2.24.138.223 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=535813765420-ues8l2u03hs7385qhcvp93teu4fceq9a.apps.googleusercontent.com

echo ""
echo "IPA ready at build/ios/ipa/*.ipa — upload via Transporter or:"
echo "  xcrun altool --upload-app --type ios -f build/ios/ipa/*.ipa --apiKey <key> --apiIssuer <issuer>"
