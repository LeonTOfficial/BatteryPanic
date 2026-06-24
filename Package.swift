// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BatteryPanic",
    defaultLocalization: nil,
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "BatteryPanicApp", targets: ["BatteryPanicApp"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "BatteryPanicApp",
            path: "Sources/BatteryPanicApp",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
