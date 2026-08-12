# Battery Panic 0.6.0 Release Notes

Battery Panic 0.6.0 introduces a native menu bar dashboard built from real battery data, with an honest local history and clearer alarm state.

## Highlights

### Real Battery Dashboard

- The menu now leads with the current battery percentage, power state, remaining-time estimate when macOS provides one, and battery health.
- Battery Panic records at most seven days of battery history locally in Application Support.
- Choose between the last 30 minutes, hour, day, or week without leaving the menu.
- Hover over the chart to see the exact stored percentage and observation time.

### Honest History, Trends, and Forecasts

- The smooth chart is drawn from recorded samples and uses a dynamically padded scale instead of inventing measurements or fixed labels.
- Charging color is limited to intervals actually reported as charging; a connected power adapter without active charging remains distinct.
- The compact average rate appears only after at least three samples cover ten minutes of one uninterrupted power phase.
- Short dashed forecasts are available for the 30-minute and one-hour views only when the same real trend is strong enough to support them.

### Clear Snooze State

- After an alarm is stopped for 30 minutes, only the menu bar percentage pulses red while the low-battery condition remains active.
- The indicator stops when the pause expires, the battery recovers, or external power is connected.
- Reduce Motion replaces the animation with a static red percentage.

### Cleanup and Runtime Hardening

- Removed the unused WidgetKit extension, App Group remnants, snapshot publisher, and the fake 68% fallback.
- Kept the real menu bar app, battery monitoring, alarms, overlay, sounds, and Sparkle updates.
- Hardened sound preview state, optional IOKit results, serialized monitoring, finite settings values, one-time onboarding, and login-item state reporting.
- Updated the vendored updater framework to Sparkle 2.9.5 without changing the public EdDSA trust root.

## Privacy

Battery history stays on the Mac. It is stored locally, retained for no more than seven days, and is not sent to an analytics service or account.

## Build

~~~bash
./scripts/run_tests.sh
./scripts/build_app.sh
~~~

The release files are written to:

~~~text
outputs/Battery Panic.app
outputs/Battery.Panic.0.6.0.zip
outputs/Battery.Panic.0.6.0.dmg
~~~

## Distribution Note

The current release package is for Apple silicon Macs (arm64) running macOS 13 or later. It is locally/ad-hoc signed and is not Apple-notarized, so macOS may require approval in System Settings -> Privacy & Security on first launch. Sparkle separately verifies the EdDSA signature of update archives.
