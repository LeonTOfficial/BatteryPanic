import Foundation

struct AlarmSettingsSnapshot: Equatable {
    let thresholdPercentage: Int
    let pulseEnabled: Bool
    let pulseSpeed: Double
    let pulseIntensity: Double
    let soundEnabled: Bool
    let selectedSoundName: String
    let launchAtLoginEnabled: Bool
    let isPaused: Bool
    let pauseUntil: Date?
    let hasCompletedOnboarding: Bool

    init(
        thresholdPercentage: Int,
        pulseEnabled: Bool,
        pulseSpeed: Double,
        pulseIntensity: Double,
        soundEnabled: Bool,
        selectedSoundName: String,
        launchAtLoginEnabled: Bool,
        isPaused: Bool,
        pauseUntil: Date? = nil,
        hasCompletedOnboarding: Bool
    ) {
        self.thresholdPercentage = thresholdPercentage
        self.pulseEnabled = pulseEnabled
        self.pulseSpeed = pulseSpeed
        self.pulseIntensity = pulseIntensity
        self.soundEnabled = soundEnabled
        self.selectedSoundName = selectedSoundName
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.isPaused = isPaused
        self.pauseUntil = pauseUntil
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

final class AppSettingsStore {
    private enum Keys {
        static let thresholdPercentage = "thresholdPercentage"
        static let pulseEnabled = "pulseEnabled"
        static let pulseSpeed = "pulseSpeed"
        static let pulseIntensity = "pulseIntensity"
        static let soundEnabled = "soundEnabled"
        static let selectedSoundName = "selectedSoundName"
        static let launchAtLoginEnabled = "launchAtLoginEnabled"
        static let legacyIsPaused = "isPaused"
        static let pauseUntil = "pauseUntil"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let completedOnboardingVersion = "completedOnboardingVersion"
        static let migratedLegacyBundleSettings = "migratedLegacyBundleSettings"
    }

    private static let legacyBundleIdentifier = "com.leontofficial.batterypanic"

    private let defaults: UserDefaults

    var onChange: ((AlarmSettingsSnapshot) -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.thresholdPercentage: AppConstants.defaultThreshold,
            Keys.pulseEnabled: true,
            Keys.pulseSpeed: 1.0,
            Keys.pulseIntensity: 1.0,
            Keys.soundEnabled: true,
            Keys.selectedSoundName: WarningSound.defaultSound.name,
            Keys.launchAtLoginEnabled: false,
            Keys.hasCompletedOnboarding: false
        ])
        migrateLegacyBundleSettingsIfNeeded()
        defaults.removeObject(forKey: Keys.legacyIsPaused)
    }

    func snapshot() -> AlarmSettingsSnapshot {
        let pauseUntil = activePauseUntil
        return AlarmSettingsSnapshot(
            thresholdPercentage: thresholdPercentage,
            pulseEnabled: defaults.bool(forKey: Keys.pulseEnabled),
            pulseSpeed: pulseSpeed,
            pulseIntensity: pulseIntensity,
            soundEnabled: defaults.bool(forKey: Keys.soundEnabled),
            selectedSoundName: selectedSoundName,
            launchAtLoginEnabled: defaults.bool(forKey: Keys.launchAtLoginEnabled),
            isPaused: pauseUntil != nil,
            pauseUntil: pauseUntil,
            hasCompletedOnboarding: hasCompletedOnboardingForCurrentVersion
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

    var selectedSoundName: String {
        let value = defaults.string(forKey: Keys.selectedSoundName) ?? WarningSound.defaultSound.name
        return WarningSound.sound(named: value).name
    }

    private var activePauseUntil: Date? {
        guard let date = defaults.object(forKey: Keys.pauseUntil) as? Date else { return nil }
        if date > Date() {
            return date
        }
        defaults.removeObject(forKey: Keys.pauseUntil)
        return nil
    }

    private var currentAppVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    private func migrateLegacyBundleSettingsIfNeeded() {
        guard !defaults.bool(forKey: Keys.migratedLegacyBundleSettings),
              let legacyDefaults = UserDefaults(suiteName: Self.legacyBundleIdentifier)
        else {
            return
        }

        let keysToMigrate = [
            Keys.thresholdPercentage,
            Keys.pulseEnabled,
            Keys.pulseSpeed,
            Keys.pulseIntensity,
            Keys.soundEnabled,
            Keys.selectedSoundName,
            Keys.launchAtLoginEnabled,
            Keys.pauseUntil,
            Keys.hasCompletedOnboarding,
            Keys.completedOnboardingVersion
        ]

        let currentDomain = Bundle.main.bundleIdentifier
            .flatMap { defaults.persistentDomain(forName: $0) } ?? [:]

        for key in keysToMigrate where currentDomain[key] == nil {
            if let value = legacyDefaults.object(forKey: key) {
                defaults.set(value, forKey: key)
            }
        }

        defaults.set(true, forKey: Keys.migratedLegacyBundleSettings)
    }

    private var hasCompletedOnboardingForCurrentVersion: Bool {
        guard defaults.bool(forKey: Keys.hasCompletedOnboarding) else { return false }
        return defaults.string(forKey: Keys.completedOnboardingVersion) == currentAppVersion
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

    func snoozeAlarm(for duration: TimeInterval = AppConstants.alarmSnoozeDuration) {
        defaults.set(Date().addingTimeInterval(duration), forKey: Keys.pauseUntil)
        notify()
    }

    func clearSnooze() {
        defaults.removeObject(forKey: Keys.pauseUntil)
        notify()
    }

    func setHasCompletedOnboarding(_ completed: Bool) {
        defaults.set(completed, forKey: Keys.hasCompletedOnboarding)
        if completed {
            defaults.set(currentAppVersion, forKey: Keys.completedOnboardingVersion)
        } else {
            defaults.removeObject(forKey: Keys.completedOnboardingVersion)
        }
        notify()
    }

    private func notify() {
        onChange?(snapshot())
    }
}
