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
            dependencies: [
                "Sparkle"
            ],
            path: "Sources/BatteryPanicApp",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement"),
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        ),
        .binaryTarget(
            name: "Sparkle",
            path: "Vendor/Sparkle/Sparkle.xcframework"
        ),
        .testTarget(
            name: "BatteryPanicAppTests",
            dependencies: ["BatteryPanicApp"],
            path: "Tests/BatteryPanicAppTests"
        )
    ]
)
