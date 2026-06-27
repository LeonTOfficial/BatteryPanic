import SwiftUI
import WidgetKit
import BatteryPanicWidgetShared

struct BatteryPanicWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: BatteryPanicWidgetSnapshot
}

struct BatteryPanicTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BatteryPanicWidgetEntry {
        BatteryPanicWidgetEntry(date: Date(), snapshot: .previewHealthy)
    }

    func getSnapshot(in context: Context, completion: @escaping (BatteryPanicWidgetEntry) -> Void) {
        let snapshot = context.isPreview ? BatteryPanicWidgetSnapshot.previewHealthy : BatteryPanicWidgetStorage.readSnapshot()
        completion(BatteryPanicWidgetEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BatteryPanicWidgetEntry>) -> Void) {
        let snapshot = BatteryPanicWidgetStorage.readSnapshot()
        let entry = BatteryPanicWidgetEntry(date: Date(), snapshot: snapshot)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date().addingTimeInterval(300)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct BatteryPanicWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BatteryPanicWidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                BatteryPanicSmallWidget(snapshot: entry.snapshot)
            case .systemMedium:
                BatteryPanicMediumWidget(snapshot: entry.snapshot)
            case .systemLarge:
                BatteryPanicLargeWidget(snapshot: entry.snapshot)
            default:
                BatteryPanicSmallWidget(snapshot: entry.snapshot)
            }
        }
        .batteryPanicWidgetBackground()
    }
}

struct BatteryPanicSmallWidget: View {
    let snapshot: BatteryPanicWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                BatteryPanicIcon(level: snapshot.level, size: 32)
                Spacer()
                StatusDot(level: snapshot.level)
            }

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(snapshot.percentage)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .monospacedDigit()
                Text("%")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
            }
            .foregroundStyle(BatteryPanicStyle.accent(for: snapshot.level))

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.compactStatus)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(BatteryPanicStyle.accent(for: snapshot.level))
                Text(snapshot.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
    }
}

struct BatteryPanicMediumWidget: View {
    let snapshot: BatteryPanicWidgetSnapshot

    var body: some View {
        HStack(spacing: 16) {
            BatteryRing(snapshot: snapshot, size: 92, lineWidth: 10)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 7) {
                    StatusDot(level: snapshot.level)
                    Text(snapshot.headline)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                }

                Text(snapshot.subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Divider().opacity(0.45)

                HStack(spacing: 10) {
                    BatteryInfoChip(title: "Threshold", value: "\(snapshot.thresholdPercentage)%")
                    BatteryInfoChip(title: "Power", value: powerLabel)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
    }

    private var powerLabel: String {
        if snapshot.isPluggedIn || snapshot.isCharging { return "Plugged" }
        return "Battery"
    }
}

struct BatteryPanicLargeWidget: View {
    let snapshot: BatteryPanicWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Battery Panic")
                        .font(.system(.title3, design: .rounded, weight: .black))
                    Text("Keep your MacBook safe.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 7) {
                    StatusDot(level: snapshot.level)
                    Text(snapshot.compactStatus)
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(BatteryPanicStyle.accent(for: snapshot.level))
                }
            }

            HStack(alignment: .center, spacing: 18) {
                BatteryRing(snapshot: snapshot, size: 118, lineWidth: 13)

                VStack(alignment: .leading, spacing: 10) {
                    Text(snapshot.headline)
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(BatteryPanicStyle.accent(for: snapshot.level))

                    Text(snapshot.subtitle)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        BatteryInfoChip(title: "Threshold", value: "\(snapshot.thresholdPercentage)%")
                        BatteryInfoChip(title: "Mode", value: snapshot.isPaused ? "Paused" : "Active")
                        BatteryInfoChip(title: "Power", value: powerLabel)
                    }
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Updated \(snapshot.updatedAt, style: .relative) ago")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: footerSymbol)
                    .foregroundStyle(BatteryPanicStyle.accent(for: snapshot.level))
            }
        }
        .padding(20)
    }

    private var powerLabel: String {
        if snapshot.isPluggedIn || snapshot.isCharging { return "Plugged" }
        return "Battery"
    }

    private var footerSymbol: String {
        switch snapshot.level {
        case .critical:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "bolt.badge.clock.fill"
        case .charging:
            return "bolt.fill"
        case .paused:
            return "pause.circle.fill"
        case .unavailable:
            return "questionmark.circle.fill"
        case .healthy:
            return "checkmark.shield.fill"
        }
    }
}

struct BatteryRing: View {
    let snapshot: BatteryPanicWidgetSnapshot
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.12), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(snapshot.percentage) / 100.0)
                .stroke(
                    BatteryPanicStyle.accent(for: snapshot.level),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(snapshot.percentage)")
                    .font(.system(size: size * 0.34, weight: .black, design: .rounded))
                    .monospacedDigit()
                Text("%")
                    .font(.system(size: size * 0.15, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

struct BatteryPanicIcon: View {
    let level: BatteryPanicWidgetLevel
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )

            Image(systemName: symbol)
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundStyle(BatteryPanicStyle.accent(for: level))
        }
        .frame(width: size, height: size)
    }

    private var symbol: String {
        switch level {
        case .critical:
            return "battery.25percent"
        case .warning:
            return "battery.50percent"
        case .charging:
            return "battery.100percent.bolt"
        case .paused:
            return "pause.circle.fill"
        case .unavailable:
            return "battery.slash"
        case .healthy:
            return "battery.75percent"
        }
    }
}

struct BatteryInfoChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 9)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct StatusDot: View {
    let level: BatteryPanicWidgetLevel

    var body: some View {
        Circle()
            .fill(BatteryPanicStyle.accent(for: level))
            .frame(width: 9, height: 9)
            .shadow(color: BatteryPanicStyle.accent(for: level).opacity(0.55), radius: 5)
    }
}

enum BatteryPanicStyle {
    static func accent(for level: BatteryPanicWidgetLevel) -> Color {
        switch level {
        case .healthy, .charging:
            return .green
        case .warning:
            return .orange
        case .critical:
            return .red
        case .paused, .unavailable:
            return .gray
        }
    }
}

struct BatteryPanicWidgetBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.055, green: 0.058, blue: 0.068),
                    Color(red: 0.012, green: 0.014, blue: 0.018)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [Color.green.opacity(0.18), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 220
            )
        }
    }
}

extension View {
    @ViewBuilder
    func batteryPanicWidgetBackground() -> some View {
        if #available(macOSApplicationExtension 14.0, *) {
            self.containerBackground(for: .widget) {
                BatteryPanicWidgetBackground()
            }
        } else {
            self.background(BatteryPanicWidgetBackground())
        }
    }
}

@main
struct BatteryPanicWidgets: Widget {
    let kind = "BatteryPanicWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BatteryPanicTimelineProvider()) { entry in
            BatteryPanicWidgetView(entry: entry)
        }
        .configurationDisplayName("Battery Panic")
        .description("Shows your MacBook battery status with Battery Panic styling.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    BatteryPanicWidgets()
} timeline: {
    BatteryPanicWidgetEntry(date: Date(), snapshot: .previewHealthy)
    BatteryPanicWidgetEntry(date: Date(), snapshot: .previewCritical)
}

#Preview(as: .systemMedium) {
    BatteryPanicWidgets()
} timeline: {
    BatteryPanicWidgetEntry(date: Date(), snapshot: .previewWarning)
}

#Preview(as: .systemLarge) {
    BatteryPanicWidgets()
} timeline: {
    BatteryPanicWidgetEntry(date: Date(), snapshot: .previewCritical)
}
