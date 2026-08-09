#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Battery Panic"
BUNDLE_ID="com.leontofficial.batterypanic.mac"
VERSION_CONFIG="$ROOT_DIR/Config/Version.xcconfig"
VERSION="$(awk -F ' = ' '$1 == "MARKETING_VERSION" { print $2 }' "$VERSION_CONFIG")"
BUILD_NUMBER="$(awk -F ' = ' '$1 == "CURRENT_PROJECT_VERSION" { print $2 }' "$VERSION_CONFIG")"
BUILD_CONFIG="${BUILD_CONFIG:-release}"
DMGBUILD_VERSION="1.6.7"
DMG_VOLUME_NAME="$APP_NAME $VERSION"
SPARKLE_FEED_URL="${SPARKLE_FEED_URL:-https://raw.githubusercontent.com/LeonTOfficial/BatteryPanic/main/appcast.xml}"
SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-XI4zReuhkT5oIylZw3eXkmtQArhooU4Q7fucZ8qndi8=}"
OUTPUT_DIR="$ROOT_DIR/outputs"
OUTPUT_APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"
RELEASE_BASE="Battery.Panic.$VERSION"
RELEASE_ZIP="$OUTPUT_DIR/$RELEASE_BASE.zip"
RELEASE_DMG="$OUTPUT_DIR/$RELEASE_BASE.dmg"
STAGING_DIR="${TMPDIR:-/tmp}/BatteryPanicBuild.$$"
DMG_MOUNT_DIR="${TMPDIR:-/tmp}/BatteryPanicDmgMount.$$"
APP_BUNDLE="$STAGING_DIR/$APP_NAME.app"
BINARY_SOURCE="$ROOT_DIR/.build/$BUILD_CONFIG/BatteryPanicApp"
BINARY_DEST="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
SPARKLE_FRAMEWORK_SOURCE="$ROOT_DIR/Vendor/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"
SPARKLE_FRAMEWORK_DEST="$APP_BUNDLE/Contents/Frameworks/Sparkle.framework"
DMGBUILD_PYTHON="python3"

cleanup() {
    if [[ -d "$DMG_MOUNT_DIR" ]]; then
        hdiutil detach "$DMG_MOUNT_DIR" >/dev/null 2>&1 || true
        rm -rf "$DMG_MOUNT_DIR"
    fi
    rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

clean_bundle_attributes() {
    xattr -cr "$APP_BUNDLE" 2>/dev/null || true
    xattr -d com.apple.FinderInfo "$APP_BUNDLE" 2>/dev/null || true
    xattr -d 'com.apple.fileprovider.fpfs#P' "$APP_BUNDLE" 2>/dev/null || true
    xattr -dr com.apple.FinderInfo "$APP_BUNDLE" 2>/dev/null || true
    xattr -dr 'com.apple.fileprovider.fpfs#P' "$APP_BUNDLE" 2>/dev/null || true
    find "$APP_BUNDLE" -exec xattr -d com.apple.FinderInfo {} \; 2>/dev/null || true
    find "$APP_BUNDLE" -exec xattr -d 'com.apple.fileprovider.fpfs#P' {} \; 2>/dev/null || true
}

clean_output_bundle_attributes() {
    xattr -cr "$OUTPUT_APP_BUNDLE" 2>/dev/null || true
    xattr -d com.apple.FinderInfo "$OUTPUT_APP_BUNDLE" 2>/dev/null || true
    xattr -d 'com.apple.fileprovider.fpfs#P' "$OUTPUT_APP_BUNDLE" 2>/dev/null || true
    xattr -dr com.apple.FinderInfo "$OUTPUT_APP_BUNDLE" 2>/dev/null || true
    xattr -dr 'com.apple.fileprovider.fpfs#P' "$OUTPUT_APP_BUNDLE" 2>/dev/null || true
    find "$OUTPUT_APP_BUNDLE" -exec xattr -d com.apple.FinderInfo {} \; 2>/dev/null || true
    find "$OUTPUT_APP_BUNDLE" -exec xattr -d 'com.apple.fileprovider.fpfs#P' {} \; 2>/dev/null || true
}

ensure_dmgbuild() {
    if "$DMGBUILD_PYTHON" - "$DMGBUILD_VERSION" <<'PY' >/dev/null 2>&1
import importlib.metadata
import sys
sys.exit(0 if importlib.metadata.version("dmgbuild") == sys.argv[1] else 1)
PY
    then
        return
    fi

    local venv_dir="$STAGING_DIR/dmgbuild-venv"
    echo "Preparing dmgbuild for styled DMG packaging..."
    python3 -m venv "$venv_dir"
    "$venv_dir/bin/python" -m pip install --upgrade pip >/dev/null
    "$venv_dir/bin/python" -m pip install "dmgbuild==$DMGBUILD_VERSION" >/dev/null
    DMGBUILD_PYTHON="$venv_dir/bin/python"
}

sign_sparkle_framework() {
    local version_dir="$SPARKLE_FRAMEWORK_DEST/Versions/B"
    codesign --force --sign - "$version_dir/XPCServices/Downloader.xpc"
    codesign --force --sign - "$version_dir/XPCServices/Installer.xpc"
    codesign --force --sign - "$version_dir/Updater.app"
    codesign --force --sign - "$SPARKLE_FRAMEWORK_DEST"

    codesign --verify --strict --verbose=2 "$version_dir/XPCServices/Downloader.xpc"
    codesign --verify --strict --verbose=2 "$version_dir/XPCServices/Installer.xpc"
    codesign --verify --strict --verbose=2 "$version_dir/Updater.app"
    codesign --verify --strict --verbose=2 "$SPARKLE_FRAMEWORK_DEST"
}

cd "$ROOT_DIR"

if [[ "${SKIP_SWIFT_BUILD:-0}" != "1" ]]; then
    swift build -c "$BUILD_CONFIG"
fi
[[ -x "$BINARY_SOURCE" ]]

rm -rf "$STAGING_DIR"
rm -rf "$OUTPUT_APP_BUNDLE"
rm -f "$OUTPUT_DIR"/Battery.Panic.*.zip
rm -f "$OUTPUT_DIR"/Battery.Panic.*.dmg
rm -f "$OUTPUT_DIR/$APP_NAME $VERSION.zip"
rm -f "$OUTPUT_DIR/$APP_NAME $VERSION.dmg"
rm -rf "$DMG_MOUNT_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$APP_BUNDLE/Contents/Frameworks"
mkdir -p "$OUTPUT_DIR"

cp "$BINARY_SOURCE" "$BINARY_DEST"
chmod +x "$BINARY_DEST"
ditto "$SPARKLE_FRAMEWORK_SOURCE" "$SPARKLE_FRAMEWORK_DEST"

if [[ ! -f "$ROOT_DIR/Resources/AppIcon.icns" ]]; then
    swift "$ROOT_DIR/scripts/create_icon.swift"
fi
swift "$ROOT_DIR/scripts/create_dmg_background.swift"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
cp "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$APP_BUNDLE/Contents/Resources/THIRD_PARTY_NOTICES.md"
cp "$ROOT_DIR/Vendor/Sparkle/LICENSE" "$APP_BUNDLE/Contents/Resources/Sparkle-LICENSE.txt"

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
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>SUEnableInstallerLauncherService</key>
    <true/>
    <key>SUEnableAutomaticChecks</key>
    <true/>
    <key>SUAutomaticallyUpdate</key>
    <true/>
    <key>SUScheduledCheckInterval</key>
    <integer>86400</integer>
    <key>SUScheduledImpatientCheckInterval</key>
    <integer>172800</integer>
    <key>SUEnableSystemProfiling</key>
    <false/>
    <key>SUFeedURL</key>
    <string>$SPARKLE_FEED_URL</string>
    <key>SUShowReleaseNotes</key>
    <true/>
    <key>SUPublicEDKey</key>
    <string>$SPARKLE_PUBLIC_ED_KEY</string>
</dict>
</plist>
PLIST

clean_bundle_attributes
sign_sparkle_framework
codesign --force --sign - "$APP_BUNDLE"
clean_bundle_attributes
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

ditto --norsrc "$APP_BUNDLE" "$OUTPUT_APP_BUNDLE"
clean_output_bundle_attributes
if ! codesign --verify --deep --strict --verbose=2 "$OUTPUT_APP_BUNDLE"; then
    echo "Warning: the loose app copy in outputs has iCloud/Finder metadata. Release ZIP/DMG are built from the clean staging app."
fi
(cd "$STAGING_DIR" && ditto -c -k --keepParent --norsrc "$APP_NAME.app" "$RELEASE_ZIP")

ensure_dmgbuild
"$DMGBUILD_PYTHON" -m dmgbuild \
    --no-hidpi \
    --settings "$ROOT_DIR/scripts/dmgbuild_settings.py" \
    -D "app=$APP_BUNDLE" \
    -D "background=$ROOT_DIR/Resources/DMGBackground.png" \
    "$DMG_VOLUME_NAME" \
    "$RELEASE_DMG" >/dev/null

clean_output_bundle_attributes

[[ -d "$OUTPUT_APP_BUNDLE" ]]
[[ ! -d "$OUTPUT_APP_BUNDLE/Contents/PlugIns" ]]
[[ -z "$(find "$OUTPUT_APP_BUNDLE" -name '*.appex' -print -quit)" ]]
[[ -d "$OUTPUT_APP_BUNDLE/Contents/Frameworks/Sparkle.framework" ]]
[[ -f "$OUTPUT_APP_BUNDLE/Contents/Resources/THIRD_PARTY_NOTICES.md" ]]
[[ -f "$OUTPUT_APP_BUNDLE/Contents/Resources/Sparkle-LICENSE.txt" ]]
[[ -f "$RELEASE_ZIP" ]]
[[ -f "$RELEASE_DMG" ]]

echo "Built app: $OUTPUT_APP_BUNDLE"
echo "Release ZIP: $RELEASE_ZIP"
echo "Release DMG: $RELEASE_DMG"
