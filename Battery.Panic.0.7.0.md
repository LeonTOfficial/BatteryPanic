# Battery Panic 0.7.0 Release Notes

Battery Panic 0.7.0 makes updates easier to notice and refines the native battery-history chart while keeping every displayed measurement honest and local.

## Highlights

### Reliable Update Notices

- Battery Panic quietly checks for updates on launch, login start, and app reopen.
- Sparkle comes to the front only when a newer update exists; automatic no-update checks and network errors stay unobtrusive.
- Manual **Check for Updates...** remains a visible foreground action.
- Release notes now open with a clear summary and an accessible **Scroll down to see all changes** cue sized for Sparkle's compact window.

### Refined Native History Chart

- The menu always opens on **Last 30 min**, with an underlined inline selector for 30 minutes, one hour, day, and week that keeps the menu open.
- The chart reveals smoothly from left to right and respects Reduce Motion.
- Grid, line, area, charging colors, and forecasts have been polished to stay readable in the compact dashboard.
- Supported dashed forecasts use real measurements from the newest uninterrupted phase for 30 minutes, one hour, and day; week remains history-only.
- Day and week keep their honest full calendar domains, using clock labels and weekdays only while hovering.
- Long recording pauses are shown as neutral dashed gaps between the two real observations around the pause. They never create hoverable or invented measurements.

### Exact Hover and Charging Markers

- Hover selects only stored points used by the visible Catmull-Rom curve, keeping the marker directly on the rendered line.
- Tooltip percentage and time remain unchanged recorded values rather than interpolated estimates.
- A small deadband reduces marker chatter while moving horizontally.
- Every visible charging section gets one bolt at its real render point nearest the section's temporal midpoint.

### Menu Polish

- **Preview alarm**, **Settings...**, and **Check for Updates...** use a shared symbol cell with optically centered symbol and text baselines.
- The current endpoint stays visible without a permanent percentage or time label.

## Privacy

Battery history stays on the Mac. It is retained for no more than seven days, is not uploaded, and release builds contain no deterministic QA fixtures or demo history.

## Distribution Note

Battery Panic 0.7.0 is an Apple silicon (`arm64`) build for macOS 13 or later. It is locally/ad-hoc signed and is not Apple-notarized, so macOS may require approval in System Settings -> Privacy & Security on first launch. Sparkle separately verifies the EdDSA signature of update archives.
