#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-0.5.9}"
SPARKLE_ACCOUNT="${SPARKLE_ACCOUNT:-BatteryPanic}"
RELEASE_FILE="$ROOT_DIR/outputs/Battery.Panic.$VERSION.zip"
APPCAST_WORK_DIR="$ROOT_DIR/work/sparkle-appcast"
DOWNLOAD_URL_PREFIX="${DOWNLOAD_URL_PREFIX:-https://github.com/LeonTOfficial/BatteryPanic/releases/download/v$VERSION/}"
PRIVATE_KEY_ENV="${SPARKLE_ED_PRIVATE_KEY:-}"

if [[ ! -f "$RELEASE_FILE" ]]; then
    echo "Missing release ZIP: $RELEASE_FILE"
    echo "Run ./scripts/build_app.sh first."
    exit 1
fi

mkdir -p "$APPCAST_WORK_DIR"
rm -f "$APPCAST_WORK_DIR"/Battery.Panic.*.zip
rm -f "$APPCAST_WORK_DIR"/Battery.Panic.*.md
cp "$RELEASE_FILE" "$APPCAST_WORK_DIR/"
cp "$ROOT_DIR/RELEASE_NOTES.md" "$APPCAST_WORK_DIR/Battery.Panic.$VERSION.md"
cp "$ROOT_DIR/RELEASE_NOTES.md" "$ROOT_DIR/Battery.Panic.$VERSION.md"

if [[ -n "$PRIVATE_KEY_ENV" ]]; then
    echo "$PRIVATE_KEY_ENV" | "$ROOT_DIR/Vendor/Sparkle/bin/generate_appcast" \
        --ed-key-file - \
        --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
        --link "https://github.com/LeonTOfficial/BatteryPanic" \
        -o "$ROOT_DIR/appcast.xml" \
        "$APPCAST_WORK_DIR"
else
    "$ROOT_DIR/Vendor/Sparkle/bin/generate_appcast" \
        --account "$SPARKLE_ACCOUNT" \
        --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
        --link "https://github.com/LeonTOfficial/BatteryPanic" \
        -o "$ROOT_DIR/appcast.xml" \
        "$APPCAST_WORK_DIR"
fi

echo "Generated appcast: $ROOT_DIR/appcast.xml"
