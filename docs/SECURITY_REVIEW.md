# Security Review

Date: 2026-06-24

## Result

Battery Panic is suitable for an initial public source release after local verification.

## Reviewed Areas

- Battery status access through IOKit power APIs.
- Login item handling through ServiceManagement.
- Local settings storage through UserDefaults.
- Overlay windows and click-through behavior.
- Build scripts and generated app bundle.
- Synthesized siren playback through AVFoundation.
- Repository ignore rules.
- Secret scanning patterns for common tokens and keys.

## Findings

- No hardcoded API keys, private keys, GitHub tokens, or OpenAI-style keys were found.
- Core warning behavior is local. Sparkle update checks can contact the configured GitHub appcast URL.
- No unnecessary macOS privacy permissions are requested.
- The siren is generated locally and does not require microphone or media-library permissions.
- Build scripts remove extended attributes before signing the app bundle.
- Public binary distribution still needs Developer ID signing and notarization.

## Verification Commands

```bash
./scripts/run_tests.sh
./scripts/build_app.sh
rm -rf /tmp/BatteryPanicZipCheck
mkdir -p /tmp/BatteryPanicZipCheck
ditto -x -k "outputs/Battery.Panic.0.5.14.zip" /tmp/BatteryPanicZipCheck
codesign --verify --deep --strict --verbose=2 "/tmp/BatteryPanicZipCheck/Battery Panic.app"
rg -n "(token|secret|password|api[_-]?key|BEGIN PRIVATE|ghp_|github_pat|sk-)" . --glob '!/.build/**' --glob '!outputs/**'
```
