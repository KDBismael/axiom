#!/usr/bin/env bash
# Bumps pubspec.yaml's build number (the +N after the version name) and
# optionally sets a new version name, so every prod build gets a fresh,
# strictly-increasing build number — required by both the App Store and
# Play Store, which both reject a re-upload of a build number they've
# already seen.
#
# Usage: bump_version.sh [new-version-name]
#   bump_version.sh            -> keeps version name, bumps build number
#   bump_version.sh 1.0.1      -> sets version name to 1.0.1, bumps build number
set -euo pipefail

cd "$(dirname "$0")/.."

current=$(grep '^version:' pubspec.yaml | sed 's/^version: *//')
name="${current%+*}"
build="${current##*+}"
new_build=$((build + 1))
new_name="${1:-$name}"
new_version="${new_name}+${new_build}"

sed -i '' "s/^version: .*/version: ${new_version}/" pubspec.yaml

echo "$new_version"
