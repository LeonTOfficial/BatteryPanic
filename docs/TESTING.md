# Testing

Run unit tests:

```bash
./scripts/run_tests.sh
```

Build the local app:

```bash
./scripts/build_app.sh
```

Manual checks:

- Open `outputs/Battery Panic.app`.
- Confirm that the first-run welcome window appears on a fresh install.
- Use `Preview Red Screen` from the welcome window, settings window, and menu bar item.
- Change pulse speed and pulse intensity, then preview the red screen again.
- Confirm the live Settings preview changes while moving pulse controls.
- Select the Battery Panic Siren and several macOS sounds, then use `Test Sound`.
- Confirm red-screen previews stop after about four seconds.
- Leave a real alarm active briefly and confirm the selected warning sound repeats until the alarm ends.
- During an active alarm, use `Pause Alarm` from the menu bar and confirm it silences only the current alarm state.
- Set the threshold above the current battery level to trigger the real alarm.
- Plug in the charger and confirm that the overlay disappears.
- Toggle sound, pulse, pause, and launch-at-login from Settings.
- Confirm the menu bar icon switches between green, orange, red, and charging states as battery state changes.
- Confirm the menu dropdown clearly shows Battery, Power, Threshold, Alarm, Overlay, and Sound.
