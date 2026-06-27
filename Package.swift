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
        .executable(name: "BatteryPanicWidgetExtension", targets: ["BatteryPanicWidgetExtension"]),
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
                "BatteryPanicWidgetShared",
                "Sparkle"
            ],
            path: "Sources/BatteryPanicApp",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("WidgetKit"),
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        ),
        .executableTarget(
            name: "BatteryPanicWidgetExtension",
            dependencies: [
                "BatteryPanicWidgetShared"
            ],
            path: "Sources/BatteryPanicWidgetExtension",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("WidgetKit")
            ]
        ),
        .binaryTarget(
            name: "Sparkle",
            path: "Vendor/Sparkle/Sparkle.xcframework"
        )
    ]
)
