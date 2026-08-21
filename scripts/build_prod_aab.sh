#!/usr/bin/env bash
# Builds a signed release Android App Bundle pointed at the production backend.
# Requires android/key.properties to be filled in (see android/key.properties
# and the upload-keystore setup steps) — otherwise the release build falls
# back to debug signing and Play Console will reject the upload.
#
# Also bumps pubspec.yaml's build number on every run (Play Console rejects
# a re-upload of a versionCode it's already seen). Pass a version name to
# also update it, e.g.: ./scripts/build_prod_aab.sh 1.0.1
set -euo pipefail

cd "$(dirname "$0")/.."

new_version=$("$(dirname "$0")/bump_version.sh" "${1:-}")
echo "Building version ${new_version}..."

flutter build appbundle \
  --dart-define=API_BASE_URL=https://server.ndeli.tech \
  --dart-define=AXIOM_PAYINS_ENABLED=false \
  --dart-define=AXIOM_PAYMENT_ENV=disabled \
  --dart-define=AXIOM_GENIUSPAY_SANDBOX_VERIFIED=false \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=535813765420-ues8l2u03hs7385qhcvp93teu4fceq9a.apps.googleusercontent.com

echo ""
echo "AAB ready at build/app/outputs/bundle/release/app-release.aab"
echo "Upload it in Play Console -> your app -> Production/Internal testing -> Create new release."
