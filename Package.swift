// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BatteryPanic",
    defaultLocalization: nil,
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "BatteryPanicApp", targets: ["BatteryPanicApp"]),
        .library(name: "BatteryPanicWidgetShared", targets: ["BatteryPanicWidgetShared"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BatteryPanicWidgetShared",
            path: "Sources/BatteryPanicWidgetShared"
        ),
        .executableTarget(
            name: "BatteryPanicApp",
            dependencies: [
                "BatteryPanicWidgetShared"
            ],
            path: "Sources/BatteryPanicApp",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("WidgetKit")
            ]
        )
    ]
)
