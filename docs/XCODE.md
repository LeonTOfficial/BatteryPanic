# Opening Battery Panic in Xcode

Battery Panic is a Swift Package based macOS project. The correct Xcode workspace is the repository root, not a newly generated `Hello, world!` Xcode template project.

## Open the project

Use one of these:

```bash
open Package.swift
```

or:

```bash
open .
```

In Xcode, use these schemes:

- `BatteryPanicApp` for the menu bar app.
- `BatteryPanicWidgetExtension` for the WidgetKit source target.
- `BatteryPanicWidgetShared` for the shared widget snapshot model.

## Do not create a new app template inside the repository

If Xcode asks to create a new macOS app project, cancel it. Creating a separate `Battery Panic/` folder with `ContentView.swift` and `Battery_PanicApp.swift` creates a second empty app and does not build the real Battery Panic code.

## Release build

For the real local app bundle, ZIP, and DMG, use:

```bash
./scripts/build_app.sh
```

The build script compiles the app and WidgetKit extension, embeds the widget into:

```text
Battery Panic.app/Contents/PlugIns/BatteryPanicWidgetExtension.appex
```

and then writes the release files into `outputs/`.
