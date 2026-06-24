import Foundation

struct WarningSound: Equatable {
    let name: String
    let displayName: String

    static let availableSounds: [WarningSound] = [
        WarningSound(name: "Basso", displayName: "Basso"),
        WarningSound(name: "Blow", displayName: "Blow"),
        WarningSound(name: "Bottle", displayName: "Bottle"),
        WarningSound(name: "Frog", displayName: "Frog"),
        WarningSound(name: "Funk", displayName: "Funk"),
        WarningSound(name: "Glass", displayName: "Glass"),
        WarningSound(name: "Hero", displayName: "Hero"),
        WarningSound(name: "Morse", displayName: "Morse"),
        WarningSound(name: "Ping", displayName: "Ping"),
        WarningSound(name: "Pop", displayName: "Pop"),
        WarningSound(name: "Purr", displayName: "Purr"),
        WarningSound(name: "Sosumi", displayName: "Sosumi"),
        WarningSound(name: "Submarine", displayName: "Submarine"),
        WarningSound(name: "Tink", displayName: "Tink")
    ]

    static let defaultSound = WarningSound(name: "Basso", displayName: "Basso")

    static func sound(named name: String) -> WarningSound {
        availableSounds.first { $0.name == name } ?? defaultSound
    }
}
