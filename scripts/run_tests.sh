#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_BINARY="$ROOT_DIR/.build/battery-panic-policy-tests"
OVERLAY_TEST_BINARY="$ROOT_DIR/.build/battery-panic-overlay-rendering-tests"

cd "$ROOT_DIR"
mkdir -p "$ROOT_DIR/.build"

swiftc \
    Sources/BatteryPanicApp/Shared/Comparable+Clamp.swift \
    Sources/BatteryPanicApp/Shared/AppConstants.swift \
    Sources/BatteryPanicApp/Battery/BatteryStatus.swift \
    Sources/BatteryPanicApp/Battery/BatteryStatus+Preview.swift \
    Sources/BatteryPanicApp/Sound/WarningSound.swift \
    Sources/BatteryPanicApp/Settings/AppSettingsStore.swift \
    Sources/BatteryPanicApp/Battery/AlarmPolicy.swift \
    Tests/BatteryPanicTests/AlarmPolicyTestRunner.swift \
    -o "$TEST_BINARY"

"$TEST_BINARY"

swiftc \
    -framework AppKit \
    Sources/BatteryPanicApp/Overlay/OverlayView.swift \
    Tests/BatteryPanicTests/OverlayRenderingTestRunner.swift \
    -o "$OVERLAY_TEST_BINARY"

"$OVERLAY_TEST_BINARY"
"$ROOT_DIR/scripts/run_icon_tests.sh"
