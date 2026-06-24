#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Battery Panic"
BUNDLE_ID="com.leontofficial.batterypanic"
VERSION="0.4.0"
BUILD_NUMBER="4"
BUILD_CONFIG="${BUILD_CONFIG:-release}"
OUTPUT_DIR="$ROOT_DIR/outputs"
OUTPUT_APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"
RELEASE_ZIP="$OUTPUT_DIR/$APP_NAME $VERSION.zip"
STAGING_DIR="${TMPDIR:-/tmp}/BatteryPanicBuild.$$"
APP_BUNDLE="$STAGING_DIR/$APP_NAME.app"
BINARY_SOURCE="$ROOT_DIR/.build/$BUILD_CONFIG/BatteryPanicApp"
BINARY_DEST="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cleanup() {
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

clean_bundle_attributes() {
    xattr -cr "$APP_BUNDLE" 2>/dev/null || true
    xattr -d com.apple.FinderInfo "$APP_BUNDLE" 2>/dev/null || true
    xattr -d 'com.apple.fileprovider.fpfs#P' "$APP_BUNDLE" 2>/dev/null || true
}

cd "$ROOT_DIR"

swift build -c "$BUILD_CONFIG"

rm -rf "$STAGING_DIR"
rm -rf "$OUTPUT_APP_BUNDLE"
rm -f "$RELEASE_ZIP"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$OUTPUT_DIR"

cp "$BINARY_SOURCE" "$BINARY_DEST"
chmod +x "$BINARY_DEST"

if [[ ! -f "$ROOT_DIR/Resources/AppIcon.icns" ]]; then
    swift "$ROOT_DIR/scripts/create_icon.swift"
fi
cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

clean_bundle_attributes
codesign --force --deep --sign - "$APP_BUNDLE"
clean_bundle_attributes
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

ditto --norsrc "$APP_BUNDLE" "$OUTPUT_APP_BUNDLE"
(cd "$STAGING_DIR" && ditto -c -k --keepParent --norsrc "$APP_NAME.app" "$RELEASE_ZIP")

echo "Built: $OUTPUT_APP_BUNDLE"
echo "Release package: $RELEASE_ZIP"
