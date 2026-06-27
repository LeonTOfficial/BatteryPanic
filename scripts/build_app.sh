#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Battery Panic"
BUNDLE_ID="com.leontofficial.batterypanic"
WIDGET_NAME="BatteryPanicWidgetExtension"
WIDGET_DISPLAY_NAME="Battery Panic Widget"
WIDGET_BUNDLE_ID="$BUNDLE_ID.widget"
VERSION="0.4.0"
BUILD_NUMBER="4"
BUILD_CONFIG="${BUILD_CONFIG:-release}"
OUTPUT_DIR="$ROOT_DIR/outputs"
OUTPUT_APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"
RELEASE_BASE="Battery.Panic.$VERSION"
RELEASE_ZIP="$OUTPUT_DIR/$RELEASE_BASE.zip"
RELEASE_DMG="$OUTPUT_DIR/$RELEASE_BASE.dmg"
STAGING_DIR="${TMPDIR:-/tmp}/BatteryPanicBuild.$$"
DMG_STAGING_DIR="${TMPDIR:-/tmp}/BatteryPanicDmg.$$"
DMG_MOUNT_DIR="${TMPDIR:-/tmp}/BatteryPanicDmgMount.$$"
DMG_FINDER_MOUNT_DIR="/Volumes/$APP_NAME $VERSION"
DMG_RW="$STAGING_DIR/$RELEASE_BASE.rw.dmg"
APP_BUNDLE="$STAGING_DIR/$APP_NAME.app"
BINARY_SOURCE="$ROOT_DIR/.build/$BUILD_CONFIG/BatteryPanicApp"
BINARY_DEST="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
WIDGET_BUNDLE="$APP_BUNDLE/Contents/PlugIns/$WIDGET_NAME.appex"
WIDGET_BINARY_SOURCE="$ROOT_DIR/.build/$BUILD_CONFIG/$WIDGET_NAME"
WIDGET_BINARY_DEST="$WIDGET_BUNDLE/Contents/MacOS/$WIDGET_NAME"

cleanup() {
    if [[ -d "$DMG_MOUNT_DIR" ]]; then
        hdiutil detach "$DMG_MOUNT_DIR" >/dev/null 2>&1 || true
        rm -rf "$DMG_MOUNT_DIR"
    fi
    if [[ -d "$DMG_FINDER_MOUNT_DIR" ]]; then
        hdiutil detach "$DMG_FINDER_MOUNT_DIR" >/dev/null 2>&1 || true
        rmdir "$DMG_FINDER_MOUNT_DIR" >/dev/null 2>&1 || true
    fi
    rm -rf "$STAGING_DIR"
    rm -rf "$DMG_STAGING_DIR"
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
rm -f "$RELEASE_DMG"
rm -f "$OUTPUT_DIR/$APP_NAME $VERSION.zip"
rm -f "$OUTPUT_DIR/$APP_NAME $VERSION.dmg"
rm -rf "$DMG_STAGING_DIR"
rm -rf "$DMG_MOUNT_DIR"
rmdir "$DMG_FINDER_MOUNT_DIR" >/dev/null 2>&1 || true
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$WIDGET_BUNDLE/Contents/MacOS"
mkdir -p "$WIDGET_BUNDLE/Contents/Resources"
mkdir -p "$OUTPUT_DIR"

cp "$BINARY_SOURCE" "$BINARY_DEST"
chmod +x "$BINARY_DEST"
cp "$WIDGET_BINARY_SOURCE" "$WIDGET_BINARY_DEST"
chmod +x "$WIDGET_BINARY_DEST"

if [[ ! -f "$ROOT_DIR/Resources/AppIcon.icns" ]]; then
    swift "$ROOT_DIR/scripts/create_icon.swift"
fi
if [[ ! -f "$ROOT_DIR/Resources/DMGBackground.png" ]]; then
    swift "$ROOT_DIR/scripts/create_dmg_background.swift"
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

cat > "$WIDGET_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>$WIDGET_DISPLAY_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$WIDGET_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$WIDGET_BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$WIDGET_DISPLAY_NAME</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
PLIST

clean_bundle_attributes
codesign --force --sign - --entitlements "$ROOT_DIR/Entitlements/BatteryPanicWidgetExtension.entitlements" "$WIDGET_BUNDLE"
codesign --force --deep --sign - --entitlements "$ROOT_DIR/Entitlements/BatteryPanicApp.entitlements" "$APP_BUNDLE"
clean_bundle_attributes
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

ditto --norsrc "$APP_BUNDLE" "$OUTPUT_APP_BUNDLE"
xattr -cr "$OUTPUT_APP_BUNDLE" 2>/dev/null || true
codesign --verify --deep --strict --verbose=2 "$OUTPUT_APP_BUNDLE"
(cd "$STAGING_DIR" && ditto -c -k --keepParent --norsrc "$APP_NAME.app" "$RELEASE_ZIP")

mkdir -p "$DMG_STAGING_DIR/.background"
ditto --norsrc "$APP_BUNDLE" "$DMG_STAGING_DIR/$APP_NAME.app"
cp "$ROOT_DIR/Resources/DMGBackground.png" "$DMG_STAGING_DIR/.background/background.png"
ln -s /Applications "$DMG_STAGING_DIR/Applications"

hdiutil create \
    -volname "$APP_NAME $VERSION" \
    -srcfolder "$DMG_STAGING_DIR" \
    -ov \
    -format UDRW \
    "$DMG_RW" >/dev/null

if [[ "${CI:-}" == "true" ]]; then
    mkdir -p "$DMG_MOUNT_DIR"
    hdiutil attach "$DMG_RW" -readwrite -noverify -noautoopen -mountpoint "$DMG_MOUNT_DIR" >/dev/null
    echo "Skipping Finder DMG layout in CI. The DMG still contains the app, Applications shortcut, and background asset."
else
    rmdir "$DMG_FINDER_MOUNT_DIR" >/dev/null 2>&1 || true
    hdiutil attach "$DMG_RW" -readwrite -noverify -mountpoint "$DMG_FINDER_MOUNT_DIR" >/dev/null
    DMG_MOUNT_DIR="$DMG_FINDER_MOUNT_DIR"
    osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$APP_NAME $VERSION"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {120, 120, 800, 540}
        set viewOptions to icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 96
        set background picture of viewOptions to (POSIX file "$DMG_MOUNT_DIR/.background/background.png" as alias)
        set position of item "$APP_NAME.app" to {190, 220}
        set position of item "Applications" to {490, 220}
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT
fi

sync
sleep 1
if [[ "${CI:-}" != "true" && ! -f "$DMG_MOUNT_DIR/.DS_Store" ]]; then
    echo "Warning: Finder did not write .DS_Store; DMG will still install correctly but may use default Finder layout."
fi
hdiutil detach "$DMG_MOUNT_DIR" >/dev/null
if [[ "$DMG_MOUNT_DIR" == "${TMPDIR:-/tmp}"/* ]]; then
    rm -rf "$DMG_MOUNT_DIR"
else
    rmdir "$DMG_MOUNT_DIR" >/dev/null 2>&1 || true
fi
hdiutil convert "$DMG_RW" -format UDZO -imagekey zlib-level=9 -o "$RELEASE_DMG" >/dev/null
xattr -cr "$OUTPUT_APP_BUNDLE" 2>/dev/null || true

[[ -d "$OUTPUT_APP_BUNDLE" ]]
[[ -d "$OUTPUT_APP_BUNDLE/Contents/PlugIns/$WIDGET_NAME.appex" ]]
[[ -f "$RELEASE_ZIP" ]]
[[ -f "$RELEASE_DMG" ]]

echo "Built app: $OUTPUT_APP_BUNDLE"
echo "Release ZIP: $RELEASE_ZIP"
echo "Release DMG: $RELEASE_DMG"
