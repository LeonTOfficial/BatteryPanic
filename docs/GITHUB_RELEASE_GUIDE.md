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

1. Run tests:

```bash
./scripts/run_tests.sh
```

2. Build packages:

```bash
./scripts/build_app.sh
```

3. Check `outputs/` contains:

```text
Battery Panic.app
Battery.Panic.0.5.15.zip
Battery.Panic.0.5.15.dmg
```

4. Confirm the ZIP contains the finished `.app`, not source code.
5. Confirm the DMG opens and supports the normal drag-and-drop install flow: `Battery Panic.app` -> `Applications`.
6. Upload both files to the GitHub Release before relying on the direct README links.
7. After uploading, the README links should resolve:
   - `https://github.com/LeonTOfficial/BatteryPanic/releases/download/v0.5.15/Battery.Panic.0.5.15.dmg`
   - `https://github.com/LeonTOfficial/BatteryPanic/releases/download/v0.5.15/Battery.Panic.0.5.15.zip`

## Release Fields

Create a new release with these values:

- Tag: `v0.5.15`
- Release title: `Battery Panic 0.5.15`
- Release label: leave as `None` for a normal release. Use `Pre-release` only if you want to clearly mark it as a test build.
- Attached binaries:
  - `outputs/Battery.Panic.0.5.15.dmg`
  - `outputs/Battery.Panic.0.5.15.zip`

Do not upload only GitHub's automatically generated source code archives as the main user download. Those are useful for developers, but normal users need the `.dmg` or `.zip` app package.

You can copy the prepared release description from:

```text
docs/RELEASE_0.5.15_TEXT.md
```

Suggested release description:

```markdown
Battery Panic 0.5.15 fixes charging reminders at startup and keeps animated warning overlays crisp.

Download:
- Recommended: `Battery.Panic.0.5.15.dmg`
- Fallback: `Battery.Panic.0.5.15.zip`

Install with DMG:
1. Download `Battery.Panic.0.5.15.dmg`.
2. Open it.
3. Drag `Battery Panic.app` into Applications.
4. Open Battery Panic from Applications.

If macOS warns that the developer cannot be verified, open [Privacy & Security settings](x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension), scroll to the bottom, and click Open Anyway / Dennoch öffnen.

What's new:
- Charging reminders no longer appear immediately after app launch or login when the battery is already at or above the configured threshold.
- Charging reminders wait for a real threshold crossing during the current charging session.
- Animated overlays clear their transparent drawing surface before every frame.
- Normal, preview, critical, and charging reminder text regions stay separately aligned.
- Added startup-session policy coverage and pixel-level overlay rendering regression tests.

Privacy:
- No analytics.
- No telemetry.
- No tracking.
- No account required.
- No network connection needed for the battery warning itself.
- Optional Sparkle update checks use the GitHub appcast.

Note: This release is locally/ad-hoc signed for open-source testing. A future public distribution build should use Apple Developer ID signing and notarization.
```

After uploading the ZIP, regenerate and commit the Sparkle appcast if needed:

```bash
./scripts/generate_appcast.sh
git add appcast.xml Battery.Panic.0.5.15.md
git commit -m "Update Sparkle appcast for 0.5.15"
git push origin main
```

## Screenshots

The README already links screenshots from `docs/screenshots/`. Use those existing images if you want visual context in the release description. Do not invent screenshots that do not match the app.

## Attribution and MIT License

Battery Panic uses the MIT License. MIT allows use, modification, distribution, and commercial use, but copies or substantial portions of the software must include the copyright and permission notice.

That means redistributions of the source code should keep the attribution to Leon / LeonTOfficial. MIT does not force every modified app UI to visibly show the creator name. If a stricter visible-attribution rule is needed, use a different license instead of standard MIT.
