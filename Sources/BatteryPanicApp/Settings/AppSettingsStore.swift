import Foundation

struct AlarmSettingsSnapshot: Equatable {
    let thresholdPercentage: Int
    let pulseEnabled: Bool
    let pulseSpeed: Double
    let pulseIntensity: Double
    let previewDuration: Double
    let soundEnabled: Bool
    let selectedSoundName: String
    let launchAtLoginEnabled: Bool
    let isPaused: Bool
    let hasCompletedOnboarding: Bool
}

final class AppSettingsStore {
    private enum Keys {
        static let thresholdPercentage = "thresholdPercentage"
        static let pulseEnabled = "pulseEnabled"
        static let pulseSpeed = "pulseSpeed"
        static let pulseIntensity = "pulseIntensity"
        static let previewDuration = "previewDuration"
        static let soundEnabled = "soundEnabled"
        static let selectedSoundName = "selectedSoundName"
        static let launchAtLoginEnabled = "launchAtLoginEnabled"
        static let isPaused = "isPaused"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    private let defaults: UserDefaults

    var onChange: ((AlarmSettingsSnapshot) -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.thresholdPercentage: AppConstants.defaultThreshold,
            Keys.pulseEnabled: true,
            Keys.pulseSpeed: 1.0,
            Keys.pulseIntensity: 1.0,
            Keys.previewDuration: AppConstants.defaultPreviewDuration,
            Keys.soundEnabled: true,
            Keys.selectedSoundName: WarningSound.defaultSound.name,
            Keys.launchAtLoginEnabled: false,
            Keys.isPaused: false,
            Keys.hasCompletedOnboarding: false
        ])
    }

    func snapshot() -> AlarmSettingsSnapshot {
        AlarmSettingsSnapshot(
            thresholdPercentage: thresholdPercentage,
            pulseEnabled: defaults.bool(forKey: Keys.pulseEnabled),
            pulseSpeed: pulseSpeed,
            pulseIntensity: pulseIntensity,
            previewDuration: previewDuration,
            soundEnabled: defaults.bool(forKey: Keys.soundEnabled),
            selectedSoundName: selectedSoundName,
            launchAtLoginEnabled: defaults.bool(forKey: Keys.launchAtLoginEnabled),
            isPaused: defaults.bool(forKey: Keys.isPaused),
            hasCompletedOnboarding: defaults.bool(forKey: Keys.hasCompletedOnboarding)
        )
    }

    var thresholdPercentage: Int {
        defaults.integer(forKey: Keys.thresholdPercentage).clamped(to: 1...50)
    }

    var pulseSpeed: Double {
        let value = defaults.double(forKey: Keys.pulseSpeed)
        return (value == 0 ? 1.0 : value).clamped(to: 0.4...2.4)
    }

    var pulseIntensity: Double {
        let value = defaults.double(forKey: Keys.pulseIntensity)
        return (value == 0 ? 1.0 : value).clamped(to: 0.45...1.6)
    }

    var previewDuration: Double {
        let value = defaults.double(forKey: Keys.previewDuration)
        return (value == 0 ? AppConstants.defaultPreviewDuration : value).clamped(to: 3...30)
    }

    var selectedSoundName: String {
        let value = defaults.string(forKey: Keys.selectedSoundName) ?? WarningSound.defaultSound.name
        return WarningSound.sound(named: value).name
    }

    func setThresholdPercentage(_ value: Int) {
        defaults.set(value.clamped(to: 1...50), forKey: Keys.thresholdPercentage)
        notify()
    }

    func setPulseEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.pulseEnabled)
        notify()
    }

    func setPulseSpeed(_ value: Double) {
        defaults.set(value.clamped(to: 0.4...2.4), forKey: Keys.pulseSpeed)
        notify()
    }

    func setPulseIntensity(_ value: Double) {
        defaults.set(value.clamped(to: 0.45...1.6), forKey: Keys.pulseIntensity)
        notify()
    }

    func setPreviewDuration(_ value: Double) {
        defaults.set(value.clamped(to: 3...30), forKey: Keys.previewDuration)
        notify()
    }

    func setSoundEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.soundEnabled)
        notify()
    }

    func setSelectedSoundName(_ name: String) {
        defaults.set(WarningSound.sound(named: name).name, forKey: Keys.selectedSoundName)
        notify()
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.launchAtLoginEnabled)
        notify()
    }

    func setPaused(_ paused: Bool) {
        defaults.set(paused, forKey: Keys.isPaused)
        notify()
    }

    func setHasCompletedOnboarding(_ completed: Bool) {
        defaults.set(completed, forKey: Keys.hasCompletedOnboarding)
        notify()
    }

    private func notify() {
        onChange?(snapshot())
    }
}
