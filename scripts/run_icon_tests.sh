#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_BINARY="$ROOT_DIR/.build/battery-panic-menu-icon-tests"

cd "$ROOT_DIR"
mkdir -p "$ROOT_DIR/.build"

swiftc \
    -framework AppKit \
    Sources/BatteryPanicApp/Shared/Comparable+Clamp.swift \
    Sources/BatteryPanicApp/Shared/AppConstants.swift \
    Sources/BatteryPanicApp/Battery/BatteryStatus.swift \
    Sources/BatteryPanicApp/MenuBar/BatteryStatusAppearance.swift \
    Sources/BatteryPanicApp/MenuBar/MenuBarIconFactory.swift \
    Tests/BatteryPanicTests/MenuBarIconTestRunner.swift \
    -o "$TEST_BINARY"

"$TEST_BINARY" "$@"
