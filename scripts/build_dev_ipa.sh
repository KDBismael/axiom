#!/usr/bin/env bash
# Builds a development-signed IPA against the development backend.
# The selected Apple team must have a development provisioning profile for
# the existing Runner bundle identifier.
set -euo pipefail

cd "$(dirname "$0")/.."

flutter build ipa \
  --export-method development \
  --dart-define-from-file=config/development.json \
  "$@"

echo ""
echo "IPA de développement : build/ios/ipa/*.ipa"
