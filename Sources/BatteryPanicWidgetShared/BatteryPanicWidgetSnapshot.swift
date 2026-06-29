import Foundation

public enum BatteryPanicWidgetLevel: String, Codable, Equatable, Sendable {
    case healthy
    case warning
    case critical
    case charging
    case paused
    case unavailable
}

public struct BatteryPanicWidgetSnapshot: Codable, Equatable, Sendable {
    public let percentage: Int
    public let hasBattery: Bool
    public let isCharging: Bool
    public let isPluggedIn: Bool
    public let thresholdPercentage: Int
    public let isPaused: Bool
    public let updatedAt: Date

    public init(
        percentage: Int,
        hasBattery: Bool,
        isCharging: Bool,
        isPluggedIn: Bool,
        thresholdPercentage: Int,
        isPaused: Bool,
        updatedAt: Date = Date()
    ) {
        self.percentage = min(100, max(0, percentage))
        self.hasBattery = hasBattery
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
        self.thresholdPercentage = min(50, max(1, thresholdPercentage))
        self.isPaused = isPaused
        self.updatedAt = updatedAt
    }

    public var level: BatteryPanicWidgetLevel {
        guard hasBattery else { return .unavailable }
        if isPaused { return .paused }
        if isPluggedIn || isCharging { return .charging }

        let warningThreshold = max(thresholdPercentage + 8, min(35, thresholdPercentage * 2))
        if percentage <= thresholdPercentage { return .critical }
        if percentage <= warningThreshold { return .warning }
        return .healthy
    }

    public var headline: String {
        switch level {
        case .healthy:
            return "Battery safe"
        case .warning:
            return "Getting low"
        case .critical:
            return "Battery critical"
        case .charging:
            return "Charging"
        case .paused:
            return "Alarm paused"
        case .unavailable:
            return "No battery"
        }
    }

    public var subtitle: String {
        switch level {
        case .healthy:
            return "No action needed."
        case .warning:
            return "Charger soon would be smart."
        case .critical:
            return "Plug in your charger now."
        case .charging:
            return "Power adapter connected."
        case .paused:
            return "Warnings are temporarily off."
        case .unavailable:
            return "Battery status is unavailable."
        }
    }

    public var compactStatus: String {
        switch level {
        case .healthy:
            return "Safe"
        case .warning:
            return "Low"
        case .critical:
            return "Critical"
        case .charging:
            return "Charging"
        case .paused:
            return "Paused"
        case .unavailable:
            return "Unavailable"
        }
    }

    public static let fallback = BatteryPanicWidgetSnapshot(
        percentage: 68,
        hasBattery: true,
        isCharging: false,
        isPluggedIn: false,
        thresholdPercentage: 10,
        isPaused: false,
        updatedAt: Date()
    )

    public static let previewHealthy = BatteryPanicWidgetSnapshot(
        percentage: 68,
        hasBattery: true,
        isCharging: false,
        isPluggedIn: false,
        thresholdPercentage: 10,
        isPaused: false,
        updatedAt: Date()
    )

    public static let previewWarning = BatteryPanicWidgetSnapshot(
        percentage: 18,
        hasBattery: true,
        isCharging: false,
        isPluggedIn: false,
        thresholdPercentage: 10,
        isPaused: false,
        updatedAt: Date()
    )

    public static let previewCritical = BatteryPanicWidgetSnapshot(
        percentage: 7,
        hasBattery: true,
        isCharging: false,
        isPluggedIn: false,
        thresholdPercentage: 10,
        isPaused: false,
        updatedAt: Date()
    )
}

public enum BatteryPanicWidgetStorage {
    public static let appGroupIdentifier = "group.com.leontofficial.batterypanic"
    public static let snapshotKey = "BatteryPanicWidgetSnapshot.v1"
    private static let snapshotFileName = "BatteryPanicWidgetSnapshot.v1.json"

    public static func readSnapshot() -> BatteryPanicWidgetSnapshot {
        if let url = snapshotFileURL,
           let data = try? Data(contentsOf: url),
           let snapshot = try? JSONDecoder().decode(BatteryPanicWidgetSnapshot.self, from: data) {
            return snapshot
        }

        guard let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(BatteryPanicWidgetSnapshot.self, from: data)
        else {
            return .fallback
        }

        return snapshot
    }

    public static func writeSnapshot(_ snapshot: BatteryPanicWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        guard let url = snapshotFileURL else { return }
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: .atomic)
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    private static var snapshotFileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent(snapshotFileName)
    }
}
