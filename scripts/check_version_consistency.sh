#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_CONFIG="$ROOT_DIR/Config/Version.xcconfig"
VERSION="$(awk -F ' = ' '$1 == "MARKETING_VERSION" { print $2 }' "$VERSION_CONFIG")"
BUILD_NUMBER="$(awk -F ' = ' '$1 == "CURRENT_PROJECT_VERSION" { print $2 }' "$VERSION_CONFIG")"

[[ -n "$VERSION" ]]
[[ -n "$BUILD_NUMBER" ]]
grep -q '<string>$(MARKETING_VERSION)</string>' "$ROOT_DIR/Config/BatteryPanicApp-Info.plist"
grep -q '<string>$(CURRENT_PROJECT_VERSION)</string>' "$ROOT_DIR/Config/BatteryPanicApp-Info.plist"
grep -q "\"version\": \"$VERSION\"" "$ROOT_DIR/website/package.json"
grep -q "Battery Panic $VERSION DMG" "$ROOT_DIR/README.md"
grep -q "<sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>" "$ROOT_DIR/appcast.xml"
grep -q "<sparkle:version>$BUILD_NUMBER</sparkle:version>" "$ROOT_DIR/appcast.xml"

echo "Version contract OK: $VERSION ($BUILD_NUMBER)"
