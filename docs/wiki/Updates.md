# Updates

Battery Panic uses Sparkle for app updates.

## Check For Updates

1. Click the Battery Panic menu bar item.
2. Choose `Check for Updates...`.
3. If a new version is available, follow the Sparkle update window.

## Version History

The update window can show release notes so you can see what changed before installing.

Release notes are hosted on the Battery Panic website and GitHub release pages.

## If An Update Fails

Try this first:

1. Quit Battery Panic completely.
2. Open the app again.
3. Choose `Check for Updates...` once more.

If it still fails, install the latest DMG manually:

https://leontofficial.github.io/BatteryPanic/download/

## Why Updates Can Fail

Sparkle updates verify that the downloaded ZIP matches the public appcast signature. This is important because it helps prevent broken or mismatched update packages.

The project also has a Release Guard workflow that checks the public release ZIP against the Sparkle appcast.
