# Security

Battery Panic is a privacy-friendly macOS utility. It does not require an account and does not collect analytics.

## Privacy Model

- Battery status is read locally through macOS power APIs.
- Settings are stored in local `UserDefaults`.
- The battery warning, menu bar status, overlay, settings, and sound features run locally.
- Optional update checks use Sparkle and contact the configured GitHub appcast URL.
- No analytics.
- No telemetry.
- No tracking.
- No account required.
- No network connection is needed for the core battery warning.
- The app does not store prompts, documents, contacts, emails, tokens, or credentials.
- The optional login item uses Apple's ServiceManagement API.

## Permissions

Battery Panic does not request Accessibility, Screen Recording, Contacts, Photos, Microphone, Camera, or Location permissions.

The app can draw a transparent warning overlay only inside the logged-in user session. It cannot draw before login or over the lock screen.

## Local Signing

The local build script ad-hoc signs the `.app` bundle so it can run on the developer's Mac. Public distribution should use a Developer ID certificate and notarization.

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
