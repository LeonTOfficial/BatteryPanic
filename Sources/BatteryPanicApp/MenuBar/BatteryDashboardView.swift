import AppKit
import Charts
import SwiftUI

final class BatteryDashboardViewModel: ObservableObject {
    private enum Keys {
        static let selectedRange = "menuDashboardHistoryRange"
    }

    @Published private(set) var status: BatteryStatus?
    @Published private(set) var settings: AlarmSettingsSnapshot
    @Published private(set) var samples: [BatteryHistorySample] = []
    @Published private(set) var trendRatePercentagePerHour: Double?
    @Published private(set) var forecast: BatteryHistoryForecast?
    @Published var selectedRange: BatteryHistoryRange {
        didSet {
            guard selectedRange != oldValue else { return }
            defaults.set(selectedRange.storageValue, forKey: Keys.selectedRange)
            refreshHistory()
        }
    }

    var onResumeAlarm: (() -> Void)?
    var onChooseHistoryRange: (() -> Void)?

    private let historyStore: BatteryHistoryStore
    private let defaults: UserDefaults
    private var rawSamples: [BatteryHistorySample] = []

    init(
        settings: AlarmSettingsSnapshot,
        historyStore: BatteryHistoryStore,
        defaults: UserDefaults = .standard
    ) {
        self.settings = settings
        self.historyStore = historyStore
        self.defaults = defaults
        selectedRange = BatteryHistoryRange(
            storageValue: defaults.string(forKey: Keys.selectedRange)
        ) ?? .thirtyMinutes
        refreshHistory()
    }

    func update(status: BatteryStatus?, settings: AlarmSettingsSnapshot) {
        self.status = status
        self.settings = settings
        refreshHistory()
    }

    func update(settings: AlarmSettingsSnapshot) {
        self.settings = settings
    }

    func resumeAlarm() {
        onResumeAlarm?()
    }

    func chooseHistoryRange() {
        onChooseHistoryRange?()
    }

    var rangeEnd: Date {
        status?.timestamp ?? historyStore.latestSample?.timestamp ?? Date()
    }

    var rangeStart: Date {
        rangeEnd.addingTimeInterval(-selectedRange.duration)
    }

    var chartEnd: Date {
        guard forecast != nil else { return rangeEnd }
        return rangeEnd.addingTimeInterval(selectedRange.duration * 0.18)
    }

    var statusTitle: String {
        guard let status, status.hasBattery else { return "Battery unavailable" }
        if status.isFinishingCharge { return "Finishing charge" }
        if status.isCharging { return "Charging" }
        if status.powerState == .connectedNotCharging {
            return status.isCharged ? "Fully charged" : "On power adapter"
        }
        if status.percentage <= AppConstants.criticalBatteryThreshold { return "Critical battery" }
        if status.percentage <= settings.thresholdPercentage { return "Low battery" }
        let warningThreshold = max(
            settings.thresholdPercentage + 8,
            min(35, settings.thresholdPercentage * 2)
        )
        return status.percentage <= warningThreshold ? "Battery getting low" : "Battery healthy"
    }

    var statusSubtitle: String {
        guard let status, status.hasBattery else {
            return "Battery status is not available."
        }
        if let remaining = BatteryFormatter.timeRemainingText(for: status) {
            return remaining
        }
        if status.isFinishingCharge {
            return "Power adapter connected."
        }
        switch status.powerState {
        case .charging:
            return "Estimating time until full…"
        case .connectedNotCharging:
            return status.isCharged ? "Power adapter connected." : "Connected, not charging."
        case .onBattery:
            return "Time remaining is not available yet."
        case .unknown:
            return "Power source is not available."
        }
    }

    var chartYDomain: ClosedRange<Double> {
        let percentages = samples.map { Double($0.percentage) }
            + [projectedChartPoint?.percentage].compactMap { $0 }
        guard let minimum = percentages.min(), let maximum = percentages.max() else {
            return 0...100
        }

        let span = max(6, maximum - minimum + 2)
        var lowerBound = minimum - ((span - (maximum - minimum)) / 2)
        var upperBound = lowerBound + span
        if lowerBound < 0 {
            upperBound -= lowerBound
            lowerBound = 0
        }
        if upperBound > 100 {
            lowerBound -= upperBound - 100
            upperBound = 100
        }
        return max(0, lowerBound)...min(100, upperBound)
    }

    /// IOKit reports integer percentages, which naturally arrive as plateaus.
    /// One real sample from the middle of every equal-percentage run gives the
    /// spline room to connect those unchanged measurements calmly. Hover uses
    /// the separate raw history, so it always reports an actual observation.
    var visualLineSamples: [BatteryHistorySample] {
        guard samples.count > 2 else { return samples }

        var groups: [[BatteryHistorySample]] = []
        for sample in samples {
            if groups.last?.last?.percentage == sample.percentage {
                groups[groups.count - 1].append(sample)
            } else {
                groups.append([sample])
            }
        }

        guard groups.count > 1 else { return samples }
        return groups.enumerated().map { index, group in
            if index == 0 { return group.first! }
            if index == groups.count - 1 { return group.last! }
            return group[group.count / 2]
        }
    }

    /// Builds independently colored line sections from recorded charging
    /// transitions. The newly observed state is a zero-width shared boundary:
    /// it closes the state that was active until that timestamp and opens the
    /// next state, so the colors meet without inventing an intermediate value.
    var visualLineSegments: [BatteryHistoryLineSegment] {
        guard visualLineSamples.count >= 2 else { return [] }

        var boundarySamples: [BatteryHistorySample] = []
        for index in rawSamples.indices.dropFirst() {
            guard rawSamples[index - 1].isCharging != rawSamples[index].isCharging else {
                continue
            }
            boundarySamples.append(rawSamples[index - 1])
            boundarySamples.append(rawSamples[index])
        }

        let sortedSamples = (visualLineSamples + boundarySamples).sorted {
            $0.timestamp < $1.timestamp
        }
        var renderSamples: [BatteryHistorySample] = []
        renderSamples.reserveCapacity(sortedSamples.count)
        for sample in sortedSamples {
            if renderSamples.last?.timestamp == sample.timestamp {
                renderSamples[renderSamples.count - 1] = sample
            } else {
                renderSamples.append(sample)
            }
        }
        guard renderSamples.count >= 2 else { return [] }

        var segments: [BatteryHistoryLineSegment] = []
        var currentSamples = [renderSamples[0]]
        var currentIsCharging = renderSamples[0].isCharging

        for sample in renderSamples.dropFirst() {
            currentSamples.append(sample)
            guard sample.isCharging != currentIsCharging else { continue }

            segments.append(
                BatteryHistoryLineSegment(
                    id: segments.count,
                    isCharging: currentIsCharging,
                    samples: currentSamples
                )
            )
            currentSamples = [sample]
            currentIsCharging = sample.isCharging
        }

        if currentSamples.count >= 2 {
            segments.append(
                BatteryHistoryLineSegment(
                    id: segments.count,
                    isCharging: currentIsCharging,
                    samples: currentSamples
                )
            )
        }
        return segments
    }

    var projectedChartPoint: DashboardChartPoint? {
        guard
            let forecast,
            let latestSample = samples.last,
            latestSample.powerSource == forecast.powerSource,
            latestSample.isCharging == forecast.isCharging
        else {
            return nil
        }

        let projectionDuration = selectedRange.duration * 0.18
        let projectedPercentage = (
            Double(latestSample.percentage)
                + forecast.ratePercentagePerHour * projectionDuration / 3_600
        ).clamped(to: 0...100)
        return DashboardChartPoint(
            timestamp: latestSample.timestamp.addingTimeInterval(projectionDuration),
            percentage: projectedPercentage,
            isEstimated: true,
            isCharging: forecast.isCharging
        )
    }

    func nearestChartPoint(to date: Date) -> DashboardChartPoint? {
        guard let nearest = nearestRawSample(to: date) else { return nil }
        return DashboardChartPoint(
            timestamp: nearest.timestamp,
            percentage: Double(nearest.percentage),
            isEstimated: false,
            isCharging: nearest.isCharging
        )
    }

    private func refreshHistory() {
        let end = rangeEnd
        rawSamples = historyStore.samples(in: selectedRange, endingAt: end)
        samples = historyStore.downsampledSamples(
            in: selectedRange,
            endingAt: end,
            maximumCount: 180
        )
        trendRatePercentagePerHour = historyStore.trendRatePercentagePerHour(
            in: selectedRange,
            endingAt: end
        )

        switch selectedRange {
        case .thirtyMinutes:
            forecast = historyStore.forecast(
                for: .thirtyMinutes,
                basedOn: .thirtyMinutes,
                endingAt: end
            )
        case .oneHour:
            forecast = historyStore.forecast(
                for: .oneHour,
                basedOn: .oneHour,
                endingAt: end
            )
        case .oneDay, .sevenDays:
            forecast = nil
        }
    }

    private func nearestRawSample(to date: Date) -> BatteryHistorySample? {
        guard !rawSamples.isEmpty else { return nil }

        var lowerBound = 0
        var upperBound = rawSamples.count
        while lowerBound < upperBound {
            let middle = (lowerBound + upperBound) / 2
            if rawSamples[middle].timestamp < date {
                lowerBound = middle + 1
            } else {
                upperBound = middle
            }
        }

        if lowerBound == 0 { return rawSamples[0] }
        if lowerBound == rawSamples.count { return rawSamples[rawSamples.count - 1] }

        let earlier = rawSamples[lowerBound - 1]
        let later = rawSamples[lowerBound]
        return date.timeIntervalSince(earlier.timestamp)
            <= later.timestamp.timeIntervalSince(date)
            ? earlier
            : later
    }
}

struct DashboardChartPoint: Equatable {
    let timestamp: Date
    let percentage: Double
    let isEstimated: Bool
    let isCharging: Bool
}

struct BatteryHistoryLineSegment: Identifiable, Equatable {
    let id: Int
    let isCharging: Bool
    let samples: [BatteryHistorySample]
}

private struct HistoryRangeButton: NSViewRepresentable {
    let title: String
    let onPress: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: title, target: context.coordinator, action: #selector(Coordinator.press(_:)))
        button.isBordered = false
        button.focusRingType = .none
        button.alignment = .left
        button.font = .systemFont(ofSize: 15, weight: .semibold)
        button.setButtonType(.momentaryChange)
        button.setAccessibilityRole(.button)
        configure(button)
        return button
    }

    func updateNSView(_ button: NSButton, context: Context) {
        context.coordinator.parent = self
        configure(button)
    }

    private func configure(_ button: NSButton) {
        button.isEnabled = true
        button.state = .off
        button.highlight(false)
        button.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
                .foregroundColor: NSColor.labelColor
            ]
        )
        button.setAccessibilityLabel("History range, \(title)")
        button.setAccessibilityHelp("Choose 30 minutes, one hour, day, or week")
    }

    final class Coordinator: NSObject {
        var parent: HistoryRangeButton

        init(parent: HistoryRangeButton) {
            self.parent = parent
        }

        @objc func press(_ sender: NSButton) {
            sender.state = .off
            sender.highlight(false)
            parent.onPress()
        }
    }
}

struct BatteryDashboardView: View {
    @ObservedObject var model: BatteryDashboardViewModel
    @State private var hoveredPoint: DashboardChartPoint?

    private let contentWidth: CGFloat = 426

    var body: some View {
        VStack(spacing: 0) {
            hero
            divider
            history
            divider
            health
            divider
            if model.settings.isPaused {
                pauseBanner
                    .padding(.horizontal, 22)
                    .padding(.top, 10)
                    .padding(.bottom, 14)
            } else {
                Spacer(minLength: 14)
            }
        }
        .frame(width: contentWidth)
        .background(Color.clear)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Battery Panic status dashboard")
    }

    private var hero: some View {
        VStack(spacing: 17) {
            HStack(alignment: .center, spacing: 20) {
                Text(percentageText)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(statusColor)
                    .frame(minWidth: 126, alignment: .leading)

                VStack(alignment: .leading, spacing: 5) {
                    Text(statusTitle)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(statusSubtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.16))
                    Capsule()
                        .fill(statusColor)
                        .frame(width: max(8, geometry.size.width * batteryFraction))
                }
            }
            .frame(height: 14)
            .accessibilityElement()
            .accessibilityLabel("Battery level")
            .accessibilityValue(percentageText)
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 20)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 13) {
            HistoryRangeButton(title: model.selectedRange.heading) {
                model.chooseHistoryRange()
            }
            .frame(width: 112, height: 20, alignment: .leading)
            .accessibilityLabel("History range, \(model.selectedRange.heading)")
            .accessibilityHint("Opens 30 minute, one hour, day, and week ranges")

            HStack(alignment: .center, spacing: 15) {
                chart
                    .frame(width: 266, height: 112)

                if let rate = model.trendRatePercentagePerHour, rate.isFinite {
                    historySummary
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 15)
    }

    @ViewBuilder
    private var chart: some View {
        if model.samples.count >= 2 {
            Chart {
                ForEach(model.visualLineSegments) { segment in
                    ForEach(segment.samples, id: \.timestamp) { sample in
                        AreaMark(
                            x: .value("Time", sample.timestamp),
                            yStart: .value("Chart baseline", model.chartYDomain.lowerBound),
                            yEnd: .value("Battery", Double(sample.percentage)),
                            series: .value("Area segment", segment.id)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    lineColor(isCharging: segment.isCharging).opacity(0.17),
                                    lineColor(isCharging: segment.isCharging).opacity(0.015)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("Battery", sample.percentage),
                            series: .value("Line segment", segment.id)
                        )
                        .foregroundStyle(lineColor(isCharging: segment.isCharging))
                        .lineStyle(
                            StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }

                if let latest = model.samples.last,
                   let projected = model.projectedChartPoint
                {
                    LineMark(
                        x: .value("Estimated time", latest.timestamp),
                        y: .value("Estimated battery", latest.percentage),
                        series: .value("Series", "Forecast")
                    )
                    .foregroundStyle(lineColor(isCharging: latest.isCharging))
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [5, 5]))

                    LineMark(
                        x: .value("Estimated time", projected.timestamp),
                        y: .value("Estimated battery", projected.percentage),
                        series: .value("Series", "Forecast")
                    )
                    .foregroundStyle(lineColor(isCharging: latest.isCharging))
                    .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [5, 5]))
                }

                if let hoveredPoint {
                    RuleMark(x: .value("Selected time", hoveredPoint.timestamp))
                        .foregroundStyle(Color.secondary.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    PointMark(
                        x: .value("Selected time", hoveredPoint.timestamp),
                        y: .value("Selected battery", hoveredPoint.percentage)
                    )
                    .symbolSize(42)
                    .foregroundStyle(
                        hoveredPoint.isEstimated
                            ? Color.orange
                            : lineColor(isCharging: hoveredPoint.isCharging)
                    )
                }
            }
            .chartXScale(domain: model.rangeStart...model.chartEnd)
            .chartYScale(domain: model.chartYDomain)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine(stroke: chartGridStroke)
                        .foregroundStyle(Color.secondary.opacity(0.14))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine(stroke: chartGridStroke)
                        .foregroundStyle(Color.secondary.opacity(0.12))
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color.secondary.opacity(0.035))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.22), lineWidth: 0.9)
                    )
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    let plotFrame = geometry[proxy.plotAreaFrame]
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .onContinuousHover(coordinateSpace: .local) { phase in
                                switch phase {
                                case .active(let location):
                                    let xPosition = location.x - plotFrame.minX
                                    guard xPosition >= 0,
                                          xPosition <= plotFrame.width,
                                          location.y >= plotFrame.minY,
                                          location.y <= plotFrame.maxY,
                                          let date: Date = proxy.value(atX: xPosition)
                                    else {
                                        hoveredPoint = nil
                                        return
                                    }
                                    hoveredPoint = model.nearestChartPoint(to: date)
                                case .ended:
                                    hoveredPoint = nil
                                }
                            }

                        if let hoveredPoint,
                           let pointX = proxy.position(forX: hoveredPoint.timestamp),
                           let pointY = proxy.position(forY: hoveredPoint.percentage)
                        {
                            let tooltipWidth: CGFloat = 116
                            let tooltipX = min(
                                max(plotFrame.minX + tooltipWidth / 2 + 5, plotFrame.minX + pointX),
                                plotFrame.maxX - tooltipWidth / 2 - 5
                            )
                            let tooltipY = min(
                                plotFrame.maxY - 17,
                                max(plotFrame.minY + 17, plotFrame.minY + pointY - 22)
                            )
                            hoverLabel(for: hoveredPoint)
                                .frame(width: tooltipWidth)
                                .position(x: tooltipX, y: tooltipY)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .onChange(of: model.selectedRange) { _ in
                hoveredPoint = nil
            }
            .accessibilityLabel("Battery history chart")
            .accessibilityValue(chartAccessibilityValue)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.035))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.22), lineWidth: 0.9)
                )
                .accessibilityLabel("Battery history is not available yet")
        }
    }

    private var historySummary: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .shadow(color: Color.red.opacity(0.20), radius: 2)

            (
                Text("Avg. ")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                + Text(averageRateValueText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            )
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.72)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(averageRateAccessibilityText)
    }

    private var health: some View {
        HStack(spacing: 12) {
            Text("Battery health")
                .font(.system(size: 15, weight: .medium))
            Spacer()
            Text(healthText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(healthColor)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .accessibilityElement(children: .combine)
    }

    private var pauseBanner: some View {
        TimelineView(.periodic(from: Date(), by: 15)) { context in
            HStack(spacing: 11) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                Text(pauseText(at: context.date))
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Button("Resume now") {
                    model.resumeAlarm()
                }
                .buttonStyle(.plain)
                .controlSize(.small)
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.orange.opacity(0.45), lineWidth: 1)
                )
            }
            .foregroundStyle(Color.orange)
            .padding(.horizontal, 14)
            .frame(height: 54)
            .background(Color.orange.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Alarm \(pauseText(at: context.date)). Resume now")
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.18))
            .frame(height: 1)
            .padding(.horizontal, 22)
    }

    private var percentageText: String {
        guard let status = model.status, status.hasBattery else { return "--%" }
        return "\(status.percentage)%"
    }

    private var batteryFraction: CGFloat {
        guard let status = model.status, status.hasBattery else { return 0 }
        return CGFloat(status.percentage) / 100
    }

    private var statusTitle: String {
        model.statusTitle
    }

    private var statusSubtitle: String {
        model.statusSubtitle
    }

    private var statusColor: Color {
        guard let status = model.status, status.hasBattery else { return .secondary }
        if status.isActivelyCharging || status.powerState == .connectedNotCharging { return .green }
        if status.percentage <= model.settings.thresholdPercentage { return .red }
        let warningThreshold = max(
            model.settings.thresholdPercentage + 8,
            min(35, model.settings.thresholdPercentage * 2)
        )
        return status.percentage <= warningThreshold ? .orange : .green
    }

    private var consumptionLineColor: Color {
        guard let status = model.status, status.hasBattery else { return .secondary }
        if status.percentage <= model.settings.thresholdPercentage { return .red }
        let warningThreshold = max(
            model.settings.thresholdPercentage + 8,
            min(35, model.settings.thresholdPercentage * 2)
        )
        return status.percentage <= warningThreshold ? .orange : .blue
    }

    private func lineColor(isCharging: Bool) -> Color {
        isCharging ? .green : consumptionLineColor
    }

    private var chartGridStroke: StrokeStyle {
        StrokeStyle(lineWidth: 0.7, lineCap: .round, dash: [3, 5])
    }

    private var averageRateValueText: String {
        guard let rate = model.trendRatePercentagePerHour, rate.isFinite else {
            return "—%/h"
        }
        let roundedRate = Int(abs(rate).rounded())
        if rate > 0 { return "+\(roundedRate)%/h" }
        if rate < 0 { return "\(roundedRate)%/h" }
        return "0%/h"
    }

    private var averageRateAccessibilityText: String {
        guard let rate = model.trendRatePercentagePerHour, rate.isFinite else {
            return "Average battery rate is not ready"
        }
        let roundedRate = Int(abs(rate).rounded())
        return rate < 0
            ? "Average battery consumption \(roundedRate) percent per hour"
            : "Average battery charge gain \(roundedRate) percent per hour"
    }

    private var healthText: String {
        if let condition = model.status?.healthCondition { return condition.displayName }
        return model.status?.health?.displayName ?? "Not reported"
    }

    private var healthColor: Color {
        if model.status?.healthCondition != nil { return .red }
        switch model.status?.health {
        case .good:
            return .green
        case .fair:
            return .orange
        case .poor:
            return .red
        case .unknown, .none:
            return .secondary
        }
    }

    private func pauseText(at date: Date) -> String {
        guard let pauseUntil = model.settings.pauseUntil else { return "Paused" }
        let remaining = max(0, Int(ceil(pauseUntil.timeIntervalSince(date) / 60)))
        return remaining == 1 ? "Paused • 1 min left" : "Paused • \(remaining) min left"
    }

    private func hoverLabel(for point: DashboardChartPoint) -> some View {
        Text("\(formattedPercentage(point.percentage)) • \(point.timestamp.formatted(date: .omitted, time: .shortened))")
            .font(.system(size: 11, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.primary)
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
    }

    private func formattedPercentage(_ percentage: Double) -> String {
        if percentage.rounded() == percentage { return "\(Int(percentage))%" }
        return "\(percentage.formatted(.number.precision(.fractionLength(1))))%"
    }

    private var chartAccessibilityValue: String {
        averageRateAccessibilityText
    }
}

extension BatteryHistoryRange {
    fileprivate init?(storageValue: String?) {
        switch storageValue {
        case "30m": self = .thirtyMinutes
        case "1h": self = .oneHour
        case "1d": self = .oneDay
        case "1w": self = .sevenDays
        default: return nil
        }
    }

    fileprivate var storageValue: String {
        switch self {
        case .thirtyMinutes: return "30m"
        case .oneHour: return "1h"
        case .oneDay: return "1d"
        case .sevenDays: return "1w"
        }
    }

    var menuTitle: String {
        switch self {
        case .thirtyMinutes: return "30 min"
        case .oneHour: return "1 h"
        case .oneDay: return "Day"
        case .sevenDays: return "Week"
        }
    }

    fileprivate var heading: String {
        switch self {
        case .thirtyMinutes: return "Last 30 min"
        case .oneHour: return "Last hour"
        case .oneDay: return "Last day"
        case .sevenDays: return "Last week"
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
