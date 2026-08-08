# Distribution Status

Battery Panic's current local/public packaging path is honest about its limits:

- The app binary is built for the architecture of the build Mac. Current public
  packages are Apple Silicon (`arm64`) only.
- Sparkle 2.9.5 is universal (`arm64` and `x86_64`), but that does not make the
  containing Battery Panic executable universal.
- Local packages are ad-hoc signed inside-out and verified after assembly.
- They are not Developer ID signed and are not notarized by Apple.

Developer ID signing, Hardened Runtime, notarization, GitHub attestations, and
immutable release/ruleset enforcement are optional release-hardening steps that
require Leon's explicit approval and the relevant external credentials. A build
must never claim those properties unless verification against the final uploaded
artifacts succeeds.

The canonical app version and build number live in `Config/Version.xcconfig`.
`scripts/check_version_consistency.sh` checks the current README, website,
Info.plist contract, and appcast for drift.
