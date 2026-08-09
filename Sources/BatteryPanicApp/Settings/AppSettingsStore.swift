import Foundation

struct AlarmSettingsSnapshot: Equatable {
    let thresholdPercentage: Int
    let chargeReminderEnabled: Bool
    let chargeReminderThresholdPercentage: Int
    let pulseEnabled: Bool
    let pulseSpeed: Double
    let pulseIntensity: Double
    let soundEnabled: Bool
    let selectedSoundName: String
    let isPaused: Bool
    let pauseUntil: Date?
    let hasCompletedOnboarding: Bool

    init(
        thresholdPercentage: Int,
        chargeReminderEnabled: Bool,
        chargeReminderThresholdPercentage: Int,
        pulseEnabled: Bool,
        pulseSpeed: Double,
        pulseIntensity: Double,
        soundEnabled: Bool,
        selectedSoundName: String,
        isPaused: Bool,
        pauseUntil: Date? = nil,
        hasCompletedOnboarding: Bool
    ) {
        self.thresholdPercentage = thresholdPercentage
        self.chargeReminderEnabled = chargeReminderEnabled
        self.chargeReminderThresholdPercentage = chargeReminderThresholdPercentage
        self.pulseEnabled = pulseEnabled
        self.pulseSpeed = pulseSpeed
        self.pulseIntensity = pulseIntensity
        self.soundEnabled = soundEnabled
        self.selectedSoundName = selectedSoundName
        self.isPaused = isPaused
        self.pauseUntil = pauseUntil
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

final class AppSettingsStore {
    private enum Keys {
        static let thresholdPercentage = "thresholdPercentage"
        static let chargeReminderEnabled = "chargeReminderEnabled"
        static let chargeReminderThresholdPercentage = "chargeReminderThresholdPercentage"
        static let pulseEnabled = "pulseEnabled"
        static let pulseSpeed = "pulseSpeed"
        static let pulseIntensity = "pulseIntensity"
        static let soundEnabled = "soundEnabled"
        static let selectedSoundName = "selectedSoundName"
        static let legacyLaunchAtLoginEnabled = "launchAtLoginEnabled"
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
            Keys.chargeReminderEnabled: true,
            Keys.chargeReminderThresholdPercentage: AppConstants.defaultChargeReminderThreshold,
            Keys.pulseEnabled: true,
            Keys.pulseSpeed: 1.0,
            Keys.pulseIntensity: 1.0,
            Keys.soundEnabled: true,
            Keys.selectedSoundName: WarningSound.defaultSound.name,
            Keys.hasCompletedOnboarding: false
        ])
        migrateLegacyBundleSettingsIfNeeded()
        defaults.removeObject(forKey: Keys.legacyIsPaused)
        defaults.removeObject(forKey: Keys.legacyLaunchAtLoginEnabled)
    }

    func snapshot() -> AlarmSettingsSnapshot {
        let pauseUntil = activePauseUntil
        return AlarmSettingsSnapshot(
            thresholdPercentage: thresholdPercentage,
            chargeReminderEnabled: defaults.bool(forKey: Keys.chargeReminderEnabled),
            chargeReminderThresholdPercentage: chargeReminderThresholdPercentage,
            pulseEnabled: defaults.bool(forKey: Keys.pulseEnabled),
            pulseSpeed: pulseSpeed,
            pulseIntensity: pulseIntensity,
            soundEnabled: defaults.bool(forKey: Keys.soundEnabled),
            selectedSoundName: selectedSoundName,
            isPaused: pauseUntil != nil,
            pauseUntil: pauseUntil,
            hasCompletedOnboarding: hasCompletedOnboarding
        )
    }

    var thresholdPercentage: Int {
        defaults.integer(forKey: Keys.thresholdPercentage).clamped(to: 1...50)
    }

    var chargeReminderThresholdPercentage: Int {
        let value = defaults.integer(forKey: Keys.chargeReminderThresholdPercentage)
        return (value == 0 ? AppConstants.defaultChargeReminderThreshold : value).clamped(to: 50...100)
    }

    var pulseSpeed: Double {
        let value = defaults.double(forKey: Keys.pulseSpeed)
        return finiteValue(value, defaultValue: 1.0, range: 0.4...2.4, key: Keys.pulseSpeed)
    }

    var pulseIntensity: Double {
        let value = defaults.double(forKey: Keys.pulseIntensity)
        return finiteValue(value, defaultValue: 1.0, range: 0.45...1.6, key: Keys.pulseIntensity)
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
            Keys.chargeReminderEnabled,
            Keys.chargeReminderThresholdPercentage,
            Keys.pulseEnabled,
            Keys.pulseSpeed,
            Keys.pulseIntensity,
            Keys.soundEnabled,
            Keys.selectedSoundName,
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

    private var hasCompletedOnboarding: Bool {
        if defaults.bool(forKey: Keys.hasCompletedOnboarding) {
            return true
        }

        guard defaults.string(forKey: Keys.completedOnboardingVersion) != nil else {
            return false
        }

        defaults.set(true, forKey: Keys.hasCompletedOnboarding)
        return true
    }

    func setThresholdPercentage(_ value: Int) {
        defaults.set(value.clamped(to: 1...50), forKey: Keys.thresholdPercentage)
        notify()
    }

    func setChargeReminderEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.chargeReminderEnabled)
        notify()
    }

    func setChargeReminderThresholdPercentage(_ value: Int) {
        defaults.set(value.clamped(to: 50...100), forKey: Keys.chargeReminderThresholdPercentage)
        notify()
    }

    func setPulseEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.pulseEnabled)
        notify()
    }

    func setPulseSpeed(_ value: Double) {
        let safeValue = value.isFinite ? value.clamped(to: 0.4...2.4) : 1.0
        defaults.set(safeValue, forKey: Keys.pulseSpeed)
        notify()
    }

    func setPulseIntensity(_ value: Double) {
        let safeValue = value.isFinite ? value.clamped(to: 0.45...1.6) : 1.0
        defaults.set(safeValue, forKey: Keys.pulseIntensity)
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

    private func finiteValue(
        _ value: Double,
        defaultValue: Double,
        range: ClosedRange<Double>,
        key: String
    ) -> Double {
        let safeValue = value.isFinite && value != 0 ? value.clamped(to: range) : defaultValue
        if value != safeValue {
            defaults.set(safeValue, forKey: key)
        }
        return safeValue
    }
}
