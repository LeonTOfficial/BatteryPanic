# GitHub Release Guide

Use this checklist when publishing Battery Panic on GitHub.

## Repository Settings

Recommended repository values:

- Repository name: `Battery-Panic` or `BatteryPanic`
- Description: `A native macOS menu bar app that shows a red pulsing warning and optional siren when your MacBook battery gets low.`
- Visibility: Public
- README: Do not generate one on GitHub if the local README already exists.
- `.gitignore`: Do not generate one on GitHub if the local `.gitignore` already exists.
- License: Do not generate one on GitHub if the local MIT `LICENSE` already exists.

## Security Settings

In GitHub, open **Settings -> Code security and analysis** and enable what is available for the repository:

- Dependabot alerts: On
- Dependabot security updates: On
- Secret scanning: On, if GitHub offers it for the repository
- Push protection: On, if GitHub offers it for the repository

In **Settings -> Actions -> General**:

- Allow GitHub Actions for this repository.
- Use read-only workflow permissions by default unless a future workflow needs write access.

In **Settings -> Branches**, consider adding a branch protection rule for `main` after the first push:

- Require status checks to pass before merging.
- Select the `macOS checks` workflow.
- Require pull requests before merging if you want a stricter workflow.

## Build a User-Friendly Release

Before creating a GitHub Release:

1. Confirm the canonical release identity in `Config/Version.xcconfig`:

```text
MARKETING_VERSION = 0.7.0
CURRENT_PROJECT_VERSION = 23
```

The app Info.plist, SwiftPM packaging script, Xcode project, website, README,
appcast, and CI checks must agree with that file. Do not introduce a second
version source.

2. Run the release checks:

```bash
./scripts/run_tests.sh
swift test
```

3. Build packages:

```bash
./scripts/build_app.sh
```

4. Generate the appcast from the exact ZIP, then verify the completed version
   contract and Sparkle signature:

```bash
./scripts/generate_appcast.sh
./scripts/check_version_consistency.sh
swift scripts/verify_appcast_update.swift outputs/Battery.Panic.0.7.0.zip
```

5. Check `outputs/` contains:

```text
Battery Panic.app
Battery.Panic.0.7.0.zip
Battery.Panic.0.7.0.dmg
```

6. Confirm the ZIP contains the finished `.app`, not source code, and reports
   version `0.7.0`, build `23`, and an `arm64` app executable.
7. Open the exact final DMG and complete a visual Finder-window QA before it
   can be uploaded:
   - Confirm the background artwork is centered in the DMG window and sized to
     the configured Finder-window dimensions without cropping, stretching,
     uncovered edges, or unintended scroll bars.
   - Confirm `Battery Panic.app`, the arrow/artwork, and the `Applications`
     shortcut remain fully visible and aligned with their intended positions.
   - Close, detach, and reopen the DMG to verify the saved window size, icon
     positions, and background layout rather than relying on the staging view.
   - Capture a screenshot of the reopened final DMG for release QA. If the
     background is not correctly centered or fitted, stop the release and fix
     the DMG layout before uploading anything.
   - Finally confirm the normal drag-and-drop flow works:
     `Battery Panic.app` -> `Applications`.
8. Verify the exact ZIP and DMG that will be uploaded. Do not reuse local
   `0.5.16` artifacts or rename an older package.
9. Commit the generated appcast and release notes, merge the reviewed release
   commits, and tag that exact `main` commit. Do not rebuild the signed ZIP.
10. Upload both files to the GitHub Release before relying on the direct README links.
11. After uploading, the README links should resolve:
   - `https://github.com/LeonTOfficial/BatteryPanic/releases/download/v0.7.0/Battery.Panic.0.7.0.dmg`
   - `https://github.com/LeonTOfficial/BatteryPanic/releases/download/v0.7.0/Battery.Panic.0.7.0.zip`

The 0.7.0 package is an Apple Silicon (`arm64`) build. Its nested Sparkle
components and app bundle are signed inside-out with an ad-hoc signature and
verified after assembly. It is not Developer ID signed, does not have an Apple
notarization ticket, and does not have a GitHub artifact attestation. Do not
claim any of those properties in release notes or announcements.

## Release Fields

Create a new release with these values:

- Tag: `v0.7.0`
- Release title: `Battery Panic 0.7.0`
- Release label: leave as `None` for a normal release. Use `Pre-release` only if you want to clearly mark it as a test build.
- Attached binaries:
  - `outputs/Battery.Panic.0.7.0.dmg`
  - `outputs/Battery.Panic.0.7.0.zip`

Do not upload only GitHub's automatically generated source code archives as the main user download. Those are useful for developers, but normal users need the `.dmg` or `.zip` app package.

You can copy the prepared release description from:

```text
docs/RELEASE_0.7.0_TEXT.md
```

Suggested release description:

```markdown
Battery Panic 0.7.0 makes update notices more reliable and refines the native
battery-history chart while keeping every measurement honest and local.

Download:
- Recommended: `Battery.Panic.0.7.0.dmg`
- Fallback: `Battery.Panic.0.7.0.zip`

Install with DMG:
1. Download `Battery.Panic.0.7.0.dmg`.
2. Open it.
3. Drag `Battery Panic.app` into Applications.
4. Open Battery Panic from Applications.

If macOS warns that the developer cannot be verified, open [Privacy & Security settings](x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension), scroll to the bottom, and click Open Anyway / Dennoch öffnen.

What's new:
- Quiet update checks on launch and reopen present Sparkle only when an update exists.
- The underlined inline range selector always starts at Last 30 min.
- The chart has a polished left-to-right reveal, hover-only clock or weekday labels,
  supported forecasts, and exact stored hover measurements.
- Genuine charging sections receive one centered bolt on a real render point.
- Day and week recording pauses appear as neutral dashed gaps between real endpoints.
- Native menu action symbols and titles share an optically centered baseline.

Privacy:
- No analytics.
- No telemetry.
- No tracking.
- No account required.
- No network connection needed for the battery warning itself.
- Optional Sparkle update checks use the GitHub appcast.

Distribution: This release is an arm64 build with an ad-hoc signature. It is
not Developer ID signed, not Apple-notarized, and has no GitHub artifact
attestation. macOS may require Open Anyway on first launch.
```

Commit the appcast generated and verified in step 4 before publishing:

```bash
git add appcast.xml Battery.Panic.0.7.0.md
git commit -m "Update Sparkle appcast for 0.7.0"
```

Generate the appcast only from the exact ZIP that will be uploaded using the existing
Battery Panic Sparkle signing key. Never rebuild or replace that ZIP afterward,
and never generate, rotate, print, or commit the private key. Merge the reviewed
release commits, tag that exact `main` commit, and upload the already verified
ZIP and DMG. After publication, wait for Release Guard and verify that its public
ZIP check is for `0.7.0` rather than an older feed item.

## Screenshots

The README already links screenshots from `docs/screenshots/`. Use those existing images if you want visual context in the release description. Do not invent screenshots that do not match the app.

## Attribution and MIT License

Battery Panic uses the MIT License. MIT allows use, modification, distribution, and commercial use, but copies or substantial portions of the software must include the copyright and permission notice.

That means redistributions of the source code should keep the attribution to Leon / LeonTOfficial. MIT does not force every modified app UI to visibly show the creator name. If a stricter visible-attribution rule is needed, use a different license instead of standard MIT.
