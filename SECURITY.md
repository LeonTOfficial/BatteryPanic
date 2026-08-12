# Security

Battery Panic is a privacy-friendly macOS utility. It does not require an account and does not collect analytics.

## Privacy Model

- Battery status is read locally through macOS power APIs.
- Settings are stored in local `UserDefaults`.
- Battery history is stored only in the app's local Application Support folder, is retained for at most seven days, and is never uploaded.
- The battery warning, menu bar status, overlay, settings, and sound features run locally.
- Optional update checks use Sparkle and contact the configured GitHub appcast URL.
- No analytics.
- No telemetry.
- No tracking.
- No account required.
- No network connection is needed for the core battery warning.
- The app does not store prompts, documents, contacts, emails, tokens, or credentials.
- The local history contains timestamps, battery percentages, and charging/power-source transitions only.
- The optional login item uses Apple's ServiceManagement API.

## Permissions

Battery Panic does not request Accessibility, Screen Recording, Contacts, Photos, Microphone, Camera, or Location permissions.

The app can draw a transparent warning overlay only inside the logged-in user session. It cannot draw before login or over the lock screen.

## Local Signing

The build script ad-hoc signs the `.app` bundle and verifies the assembled signature. Current public packages use this same ad-hoc signing path and are not Apple-notarized, so macOS may require first-launch approval in Privacy & Security. Developer ID signing and notarization would remove that limitation in a future distribution step.

## GitHub Security Settings

For the public GitHub repository, enable these settings when available:

- Dependabot alerts.
- Dependabot security updates.
- Secret scanning.
- Push protection.
- GitHub Actions with read-only default workflow permissions.
- Optional branch protection for `main` after the first push.

See [`docs/GITHUB_RELEASE_GUIDE.md`](docs/GITHUB_RELEASE_GUIDE.md) for the release and repository checklist.

## Security Review Checklist

Before publishing a release:

- Run `./scripts/run_tests.sh`.
- Run `./scripts/build_app.sh`.
- Run a secret scan such as:

```bash
rg -n "(token|secret|password|api[_-]?key|BEGIN PRIVATE|ghp_|github_pat|sk-)" . --glob '!/.build/**' --glob '!outputs/**'
```

- Confirm `.build/`, `.swiftpm/`, `outputs/`, `.DS_Store`, and local work files are not committed.
- Confirm the app bundle signature verifies with `codesign --verify --deep --strict`.

## Reporting

Please open a GitHub issue for ordinary bugs. If you find a security-sensitive issue, report it privately to the maintainer before publishing details.
