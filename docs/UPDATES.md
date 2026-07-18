# Updating Battery Panic

Battery Panic uses Sparkle for update checks outside the Mac App Store.

## User experience

The app adds a menu item:

```text
Check for Updates...
```

Sparkle reads:

```text
https://raw.githubusercontent.com/LeonTOfficial/BatteryPanic/main/appcast.xml
```

and compares the installed app version with the newest signed update in the feed.

## Signing keys

Sparkle updates are signed with an EdDSA key. The public key is committed in the app build script:

```text
XI4zReuhkT5oIylZw3eXkmtQArhooU4Q7fucZ8qndi8=
```

The private key is not committed. Locally, it is stored in the macOS Keychain under this Sparkle account:

```text
BatteryPanic
```

To show the public key again:

```bash
Vendor/Sparkle/bin/generate_keys --account BatteryPanic -p
```

## Release workflow

1. Update the version in `scripts/build_app.sh`.
2. Build the app:

```bash
./scripts/build_app.sh
```

3. Generate/update the appcast:

```bash
./scripts/generate_appcast.sh
```

4. Commit `appcast.xml` and release notes.
5. Push to GitHub.
6. Create a GitHub release tag matching the version, for example `v0.5.14`.
7. Upload:

```text
outputs/Battery.Panic.0.5.14.zip
outputs/Battery.Panic.0.5.14.dmg
```

The appcast should point to the ZIP because Sparkle installs app updates from the ZIP archive. The DMG is still useful for first-time manual installation.

8. Verify the uploaded GitHub ZIP against the committed Sparkle appcast:

```bash
swift scripts/verify_appcast_update.swift
```

If this fails, do not publish the release as ready. Regenerate `appcast.xml` from the exact ZIP that is uploaded to GitHub, then commit and push the fixed appcast.

## CI / another Mac

If the private Sparkle key is not in the local Keychain, pass it through an environment variable:

```bash
SPARKLE_ED_PRIVATE_KEY="..." ./scripts/generate_appcast.sh
```

Never commit the private key.
