import Foundation

enum WarningSoundSource: Equatable {
    case system
    case siren
}

struct WarningSound: Equatable {
    let name: String
    let displayName: String
    let source: WarningSoundSource

    static let availableSounds: [WarningSound] = [
        WarningSound(name: "BatteryPanicSiren", displayName: "Battery Panic Siren", source: .siren),
        WarningSound(name: "Basso", displayName: "Basso", source: .system),
        WarningSound(name: "Blow", displayName: "Blow", source: .system),
        WarningSound(name: "Bottle", displayName: "Bottle", source: .system),
        WarningSound(name: "Frog", displayName: "Frog", source: .system),
        WarningSound(name: "Funk", displayName: "Funk", source: .system),
        WarningSound(name: "Glass", displayName: "Glass", source: .system),
        WarningSound(name: "Hero", displayName: "Hero", source: .system),
        WarningSound(name: "Morse", displayName: "Morse", source: .system),
        WarningSound(name: "Ping", displayName: "Ping", source: .system),
        WarningSound(name: "Pop", displayName: "Pop", source: .system),
        WarningSound(name: "Purr", displayName: "Purr", source: .system),
        WarningSound(name: "Sosumi", displayName: "Sosumi", source: .system),
        WarningSound(name: "Submarine", displayName: "Submarine", source: .system),
        WarningSound(name: "Tink", displayName: "Tink", source: .system)
    ]

    static let defaultSound = WarningSound(name: "BatteryPanicSiren", displayName: "Battery Panic Siren", source: .siren)

    static func sound(named name: String) -> WarningSound {
        availableSounds.first { $0.name == name } ?? defaultSound
    }
}
