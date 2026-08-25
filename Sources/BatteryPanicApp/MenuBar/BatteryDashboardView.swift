import AppKit
import Charts
import SwiftUI

final class BatteryDashboardViewModel: ObservableObject {
    static let missingHistoryGapThreshold: TimeInterval = 3 * 60

    @Published private(set) var status: BatteryStatus?
    @Published private(set) var settings: AlarmSettingsSnapshot
    @Published private(set) var samples: [BatteryHistorySample] = []
    @Published private(set) var trendRatePercentagePerHour: Double?
    @Published private(set) var forecast: BatteryHistoryForecast?
    @Published private(set) var isRangePickerExpanded = false
    @Published private(set) var revealGeneration = 0
    @Published var selectedRange: BatteryHistoryRange {
        didSet {
            guard selectedRange != oldValue else { return }
            refreshHistory()
        }
    }

    var onResumeAlarm: (() -> Void)?
    var onRangePickerVisibilityChange: ((Bool) -> Void)?

    private let historyStore: BatteryHistoryStore
    private var rawSamples: [BatteryHistorySample] = []

    init(
        settings: AlarmSettingsSnapshot,
        historyStore: BatteryHistoryStore,
        defaults: UserDefaults = .standard
    ) {
        self.settings = settings
        self.historyStore = historyStore
        _ = defaults
        selectedRange = .thirtyMinutes
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

    func toggleRangePicker() {
        setRangePickerExpanded(!isRangePickerExpanded)
    }

    func selectRange(_ range: BatteryHistoryRange) {
        selectedRange = range
        setRangePickerExpanded(false)
    }

    func prepareForMenuOpening() {
        if selectedRange == .thirtyMinutes {
            refreshHistory()
        } else {
            selectedRange = .thirtyMinutes
        }
        setRangePickerExpanded(false)
        revealGeneration += 1
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

    var chartRevealStartFraction: Double {
        guard let firstSample = renderedLineSamples.first else { return 0 }
        let domainDuration = chartEnd.timeIntervalSince(chartStart)
        guard domainDuration > 0 else { return 0 }
        return (
            firstSample.timestamp.timeIntervalSince(chartStart) / domainDuration
        ).clamped(to: 0...1)
    }

    /// Short ranges keep the first real observation on the leading edge so a
    /// newly opened app remains useful. Day and week retain their full honest
    /// calendar domain even when only a small amount of history exists; the
    /// unrecorded portion stays empty instead of receiving fixture values.
    var chartStart: Date {
        switch selectedRange {
        case .oneDay, .sevenDays:
            return rangeStart
        case .thirtyMinutes, .oneHour:
            return renderedLineSamples.first?.timestamp ?? rangeStart
        }
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
        -8...108
    }

    /// Tick positions are anchored to the real visible history, never to an
    /// invented sample. Short ranges use relative durations while day and
    /// week ranges use true local calendar boundaries.
    var hoverTimeAxisTicks: [DashboardTimeAxisTick] {
        switch selectedRange {
        case .thirtyMinutes, .oneHour:
            return relativeTimeAxisTicks
        case .oneDay:
            return dayClockAxisTicks
        case .sevenDays:
            return weekdayAxisTicks
        }
    }

    private var relativeTimeAxisTicks: [DashboardTimeAxisTick] {
        let visibleDuration = max(0, rangeEnd.timeIntervalSince(chartStart))
        let fractions = selectedRange.axisFractions
        let labels: [String]
        if visibleDuration >= selectedRange.duration * 0.95 {
            labels = selectedRange.referenceAxisLabels
        } else {
            labels = fractions.enumerated().map { index, fraction in
                if index == fractions.count - 1 { return "now" }
                let remainingDuration = visibleDuration * (1 - fraction)
                let relative = Self.shortAxisDuration(remainingDuration)
                return relative
            }
        }

        return zip(fractions, labels).map { fraction, label in
            DashboardTimeAxisTick(
                timestamp: chartStart.addingTimeInterval(visibleDuration * fraction),
                label: label
            )
        }
    }

    private var dayClockAxisTicks: [DashboardTimeAxisTick] {
        let calendar = Calendar.current
        var ticks: [DashboardTimeAxisTick] = []
        var candidate = calendar.dateInterval(of: .hour, for: chartStart)?.start
            ?? chartStart

        if candidate <= chartStart {
            candidate = calendar.date(byAdding: .hour, value: 1, to: candidate) ?? rangeEnd
        }
        while candidate <= rangeEnd,
              calendar.component(.hour, from: candidate) % 4 != 0
        {
            candidate = calendar.date(byAdding: .hour, value: 1, to: candidate) ?? rangeEnd
        }

        while candidate <= rangeEnd {
            let hour = calendar.component(.hour, from: candidate)
            ticks.append(
                DashboardTimeAxisTick(
                    timestamp: candidate,
                    label: String(format: "%02d:00", hour)
                )
            )
            guard let next = calendar.date(byAdding: .hour, value: 4, to: candidate),
                  next > candidate
            else { break }
            candidate = next
        }

        // Keep the live endpoint readable when it sits shortly after the last
        // four-hour boundary. Removing a label does not alter any chart data.
        if let last = ticks.last,
           rangeEnd.timeIntervalSince(last.timestamp) < 2 * 60 * 60
        {
            ticks.removeLast()
        }
        ticks.append(DashboardTimeAxisTick(timestamp: rangeEnd, label: "now"))
        return ticks
    }

    private var weekdayAxisTicks: [DashboardTimeAxisTick] {
        let calendar = Calendar.current
        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        guard var candidate = calendar.nextDate(
            after: chartStart,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime,
            direction: .forward
        ) else { return [] }

        var ticks: [DashboardTimeAxisTick] = []
        while candidate <= rangeEnd {
            let weekday = calendar.component(.weekday, from: candidate)
            ticks.append(
                DashboardTimeAxisTick(
                    timestamp: candidate,
                    label: symbols[weekday - 1]
                )
            )
            guard let next = calendar.date(byAdding: .day, value: 1, to: candidate),
                  next > candidate
            else { break }
            candidate = next
        }
        return ticks
    }

    func hoverTimeAxisLabel(for timestamp: Date) -> String? {
        hoverTimeAxisTicks.min {
            abs($0.timestamp.timeIntervalSince(timestamp))
                < abs($1.timestamp.timeIntervalSince(timestamp))
        }.flatMap { tick in
            abs(tick.timestamp.timeIntervalSince(timestamp)) < 0.5 ? tick.label : nil
        }
    }

    private static func shortAxisDuration(_ duration: TimeInterval) -> String {
        let seconds = max(0, duration)
        if seconds >= 24 * 60 * 60 {
            return "\(Int((seconds / (24 * 60 * 60)).rounded()))d"
        }
        if seconds >= 60 * 60 {
            return "\(Int((seconds / (60 * 60)).rounded()))h"
        }
        if seconds >= 60 {
            return "\(Int((seconds / 60).rounded()))m"
        }
        return "\(Int(seconds.rounded()))s"
    }

    /// IOKit reports integer percentages, which naturally arrive as plateaus.
    /// One real sample from the middle of every equal-percentage run gives the
    /// spline room to connect those unchanged measurements calmly.
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

    /// The exact recorded points that are supplied to the visible spline.
    /// Hover deliberately selects only from this set so its marker shares the
    /// same chart coordinate as the rendered Catmull-Rom control point.
    var renderedLineSamples: [BatteryHistorySample] {
        var boundarySamples: [BatteryHistorySample] = []
        for index in rawSamples.indices.dropFirst() {
            let previous = rawSamples[index - 1]
            let current = rawSamples[index]
            if lineStyle(for: previous) != lineStyle(for: current) {
                boundarySamples.append(previous)
                boundarySamples.append(current)
            }
            if showsMissingHistoryGaps,
               current.timestamp.timeIntervalSince(previous.timestamp)
                    > Self.missingHistoryGapThreshold
            {
                boundarySamples.append(previous)
                boundarySamples.append(current)
            }
        }

        let sortedSamples = (visualLineSamples + boundarySamples).sorted {
            $0.timestamp < $1.timestamp
        }
        var renderedSamples: [BatteryHistorySample] = []
        renderedSamples.reserveCapacity(sortedSamples.count)
        for sample in sortedSamples {
            if renderedSamples.last?.timestamp == sample.timestamp {
                renderedSamples[renderedSamples.count - 1] = sample
            } else {
                renderedSamples.append(sample)
            }
        }
        return renderedSamples
    }

    /// One real render point nearest the temporal midpoint of every visible
    /// charging segment. The marker therefore sits directly on the green
    /// spline without introducing an interpolated time or percentage.
    var chargingMarkerSamples: [BatteryHistorySample] {
        visualLineSegments.compactMap { segment in
            guard segment.style == .charging,
                  let first = segment.samples.first,
                  let last = segment.samples.last
            else {
                return nil
            }

            let midpoint = first.timestamp.timeIntervalSinceReferenceDate
                + last.timestamp.timeIntervalSince(first.timestamp) / 2
            return segment.samples.min { left, right in
                let leftDistance = abs(left.timestamp.timeIntervalSinceReferenceDate - midpoint)
                let rightDistance = abs(right.timestamp.timeIntervalSinceReferenceDate - midpoint)
                if leftDistance == rightDistance {
                    return left.timestamp < right.timestamp
                }
                return leftDistance < rightDistance
            }
        }
    }

    /// Builds independently colored line sections from recorded charging
    /// transitions. The newly observed state is a zero-width shared boundary:
    /// it closes the state that was active until that timestamp and opens the
    /// next state, so the colors meet without inventing an intermediate value.
    var visualLineSegments: [BatteryHistoryLineSegment] {
        let renderSamples = renderedLineSamples
        guard renderSamples.count >= 2 else { return [] }

        var segments: [BatteryHistoryLineSegment] = []
        var currentSamples = [renderSamples[0]]
        var currentStyle = lineStyle(for: renderSamples[0])

        for sample in renderSamples.dropFirst() {
            let previousSample = currentSamples.last!
            if isMissingHistoryGap(from: previousSample, to: sample)
            {
                appendLineSegment(
                    style: currentStyle,
                    samples: currentSamples,
                    to: &segments
                )
                segments.append(
                    BatteryHistoryLineSegment(
                        id: segments.count,
                        style: .noData,
                        samples: [previousSample, sample]
                    )
                )
                currentSamples = [sample]
                currentStyle = lineStyle(for: sample)
                continue
            }

            currentSamples.append(sample)
            let sampleStyle = lineStyle(for: sample)
            guard sampleStyle != currentStyle else { continue }

            appendLineSegment(
                style: currentStyle,
                samples: currentSamples,
                to: &segments
            )
            currentSamples = [sample]
            currentStyle = sampleStyle
        }

        appendLineSegment(style: currentStyle, samples: currentSamples, to: &segments)
        return segments
    }

    private var showsMissingHistoryGaps: Bool {
        selectedRange == .oneDay || selectedRange == .sevenDays
    }

    private func isMissingHistoryGap(
        from previous: BatteryHistorySample,
        to current: BatteryHistorySample
    ) -> Bool {
        guard showsMissingHistoryGaps,
              current.timestamp.timeIntervalSince(previous.timestamp)
                > Self.missingHistoryGapThreshold
        else {
            return false
        }

        return !rawSamples.contains {
            $0.timestamp > previous.timestamp && $0.timestamp < current.timestamp
        }
    }

    private func appendLineSegment(
        style: BatteryHistoryLineStyle,
        samples: [BatteryHistorySample],
        to segments: inout [BatteryHistoryLineSegment]
    ) {
        guard samples.count >= 2 else { return }
        segments.append(
            BatteryHistoryLineSegment(
                id: segments.count,
                style: style,
                samples: samples
            )
        )
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
            style: lineStyle(for: latestSample)
        )
    }

    func nearestChartPoint(to date: Date) -> DashboardChartPoint? {
        guard let nearest = nearestRenderedSample(to: date) else { return nil }
        return DashboardChartPoint(
            timestamp: nearest.timestamp,
            percentage: Double(nearest.percentage),
            isEstimated: false,
            style: lineStyle(for: nearest)
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
        case .oneDay:
            forecast = historyStore.forecast(
                for: .oneDay,
                basedOn: .oneDay,
                endingAt: end
            )
        case .sevenDays:
            forecast = nil
        }
    }

    func lineStyle(for sample: BatteryHistorySample) -> BatteryHistoryLineStyle {
        if sample.isCharging { return .charging }
        if sample.powerSource == .batteryPower { return .discharging }
        return .connectedNotCharging
    }

    private func setRangePickerExpanded(_ expanded: Bool) {
        guard isRangePickerExpanded != expanded else { return }
        isRangePickerExpanded = expanded
        onRangePickerVisibilityChange?(expanded)
    }

    private func nearestRenderedSample(to date: Date) -> BatteryHistorySample? {
        let renderedSamples = renderedLineSamples
        guard !renderedSamples.isEmpty else { return nil }

        var lowerBound = 0
        var upperBound = renderedSamples.count
        while lowerBound < upperBound {
            let middle = (lowerBound + upperBound) / 2
            if renderedSamples[middle].timestamp < date {
                lowerBound = middle + 1
            } else {
                upperBound = middle
            }
        }

        if lowerBound == 0 { return renderedSamples[0] }
        if lowerBound == renderedSamples.count { return renderedSamples[renderedSamples.count - 1] }

        let earlier = renderedSamples[lowerBound - 1]
        let later = renderedSamples[lowerBound]
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
    let style: BatteryHistoryLineStyle
}

enum DashboardHoverSelectionPolicy {
    static let switchingDeadband: CGFloat = 1.75

    static func shouldSwitch(
        currentX: CGFloat,
        candidateX: CGFloat,
        pointerX: CGFloat
    ) -> Bool {
        guard currentX != candidateX else { return false }
        let midpoint = (currentX + candidateX) / 2
        if candidateX > currentX {
            return pointerX >= midpoint + switchingDeadband
        }
        return pointerX <= midpoint - switchingDeadband
    }
}

struct DashboardTimeAxisTick: Equatable {
    let timestamp: Date
    let label: String
}

private struct DashboardHoverPulseSymbol: View {
    let color: Color
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            let scale = pulseScale(at: context.date)
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .scaleEffect(scale)
        }
        .frame(width: 7.3, height: 7.3)
    }

    private func pulseScale(at date: Date) -> CGFloat {
        guard !reduceMotion else { return 1 }
        let phase = date.timeIntervalSinceReferenceDate * (2 * Double.pi / 1.6)
        return 1 + CGFloat((sin(phase) + 1) * 0.0175)
    }
}

struct BatteryHistoryLineSegment: Identifiable, Equatable {
    let id: Int
    let style: BatteryHistoryLineStyle
    let samples: [BatteryHistorySample]
}

enum BatteryHistoryLineStyle: Equatable {
    case charging
    case discharging
    case connectedNotCharging
    case noData
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
                .foregroundColor: NSColor.labelColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: NSColor.labelColor.withAlphaComponent(0.72)
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

/// SwiftUI's continuous-hover gesture does not reliably receive mouse-move
/// events while an NSMenu is running its tracking loop. An AppKit tracking
/// area remains active inside that loop and feeds exact local coordinates back
/// to the chart overlay.
struct DashboardHoverTrackingView: NSViewRepresentable {
    let onMove: (CGPoint) -> Void
    let onExit: () -> Void

    func makeNSView(context: Context) -> HoverTrackingNSView {
        let view = HoverTrackingNSView()
        view.onMove = onMove
        view.onExit = onExit
        return view
    }

    func updateNSView(_ view: HoverTrackingNSView, context: Context) {
        view.onMove = onMove
        view.onExit = onExit
    }

    final class HoverTrackingNSView: NSView {
        var onMove: ((CGPoint) -> Void)?
        var onExit: (() -> Void)?
        private var hoverTrackingArea: NSTrackingArea?

        override var isFlipped: Bool { true }

        override func updateTrackingAreas() {
            if let hoverTrackingArea {
                removeTrackingArea(hoverTrackingArea)
            }
            let trackingArea = NSTrackingArea(
                rect: .zero,
                options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(trackingArea)
            hoverTrackingArea = trackingArea
            super.updateTrackingAreas()
        }

        override func mouseEntered(with event: NSEvent) {
            publishLocation(from: event)
        }

        override func mouseMoved(with event: NSEvent) {
            publishLocation(from: event)
        }

        override func mouseExited(with event: NSEvent) {
            onExit?()
        }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            true
        }

        private func publishLocation(from event: NSEvent) {
            onMove?(convert(event.locationInWindow, from: nil))
        }
    }
}

struct BatteryDashboardView: View {
    @ObservedObject var model: BatteryDashboardViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hoveredPoint: DashboardChartPoint?
    @State private var revealProgress: CGFloat = 1

    private let contentWidth: CGFloat = 426
    private let reduceMotionOverride: Bool?
    private let preservesInitialHoverForQA: Bool

    init(
        model: BatteryDashboardViewModel,
        reduceMotionOverride: Bool? = nil,
        initialHoveredPoint: DashboardChartPoint? = nil
    ) {
        self.model = model
        self.reduceMotionOverride = reduceMotionOverride
        preservesInitialHoverForQA = initialHoveredPoint != nil
        _hoveredPoint = State(initialValue: initialHoveredPoint)
    }

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
        .onAppear {
            if preservesInitialHoverForQA {
                revealProgress = 1
            } else {
                startChartReveal()
            }
        }
        .onChange(of: model.revealGeneration) { _ in
            startChartReveal()
        }
        .onChange(of: reduceMotion) { enabled in
            if reduceMotionOverride ?? enabled {
                revealProgress = 1
            }
        }
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
                withAnimation(rangePickerAnimation) {
                    model.toggleRangePicker()
                }
            }
            .frame(width: 112, height: 20, alignment: .leading)
            .accessibilityLabel("History range, \(model.selectedRange.heading)")
            .accessibilityHint("Opens 30 minute, one hour, day, and week ranges")

            if model.isRangePickerExpanded {
                historyRangePicker
                    .transition(
                        .opacity
                            .combined(with: .scale(scale: 0.96, anchor: .top))
                    )
            }

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

    private var historyRangePicker: some View {
        HStack(spacing: 5) {
            ForEach(BatteryHistoryRange.allCases, id: \.self) { range in
                Text(range.menuTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(range == model.selectedRange ? Color.white : Color.primary)
                    .frame(maxWidth: .infinity, minHeight: 25)
                    .background(
                        Capsule()
                            .fill(
                                range == model.selectedRange
                                    ? Color.accentColor
                                    : Color.secondary.opacity(0.10)
                            )
                    )
                    .contentShape(Capsule())
                    .onTapGesture {
                        selectHistoryRange(range)
                    }
                    .accessibilityElement()
                    .accessibilityLabel("Show battery history for \(range.accessibilityTitle)")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAddTraits(range == model.selectedRange ? .isSelected : [])
                    .accessibilityAction {
                        selectHistoryRange(range)
                    }
                }
        }
        .padding(3)
        .background(Color.secondary.opacity(0.07), in: Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Battery history range")
    }

    @ViewBuilder
    private var chart: some View {
        if model.samples.count >= 2 {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.045))
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.28), lineWidth: 0.9)
                chartGridLayer
                chartMarksLayer
                    .mask(alignment: .leading) {
                        GeometryReader { geometry in
                            let startX = geometry.size.width
                                * model.chartRevealStartFraction
                            Rectangle()
                                .frame(
                                    width: (geometry.size.width - startX) * revealProgress
                                )
                                .offset(x: startX)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .allowsHitTesting(false)
                chartInteractionLayer
                    .allowsHitTesting(revealProgress >= 0.999)
            }
            .onChange(of: model.selectedRange) { _ in
                hoveredPoint = nil
                startChartReveal()
            }
            .onDisappear {
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

    private var chartGridLayer: some View {
        Chart {
            if let first = model.renderedLineSamples.first {
                PointMark(
                    x: .value("Range start", first.timestamp),
                    y: .value("Range minimum", model.chartYDomain.lowerBound)
                )
                .foregroundStyle(Color.clear)
            }
            if let projected = model.projectedChartPoint {
                PointMark(
                    x: .value("Range end", projected.timestamp),
                    y: .value("Range maximum", model.chartYDomain.upperBound)
                )
                .foregroundStyle(Color.clear)
            }
        }
        .chartXScale(domain: model.chartStart...model.chartEnd)
        .chartYScale(domain: model.chartYDomain)
        .chartXAxis {
            AxisMarks(values: model.hoverTimeAxisTicks.map(\.timestamp)) { _ in
                AxisGridLine(stroke: chartGridStroke)
                    .foregroundStyle(Color.secondary.opacity(0.15))
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { _ in
                AxisGridLine(stroke: chartGridStroke)
                    .foregroundStyle(Color.secondary.opacity(0.13))
            }
        }
        .chartPlotStyle { plotArea in
            plotArea.background(Color.clear)
        }
        .allowsHitTesting(false)
    }

    private var chartMarksLayer: some View {
        Chart {
            ForEach(model.visualLineSegments) { segment in
                ForEach(segment.samples, id: \.timestamp) { sample in
                    if segment.style != .noData {
                        AreaMark(
                            x: .value("Time", sample.timestamp),
                            yStart: .value("Chart baseline", model.chartYDomain.lowerBound),
                            yEnd: .value("Battery", Double(sample.percentage)),
                            series: .value("Area segment", segment.id)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    lineColor(for: segment.style).opacity(0.16),
                                    lineColor(for: segment.style).opacity(0.025)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }

                    LineMark(
                        x: .value("Time", sample.timestamp),
                        y: .value("Battery", sample.percentage),
                        series: .value("Line segment", segment.id)
                    )
                    .foregroundStyle(lineColor(for: segment.style))
                    .lineStyle(
                        segment.style == .noData
                            ? StrokeStyle(
                                lineWidth: 1.45,
                                lineCap: .round,
                                lineJoin: .round,
                                dash: [3, 3]
                            )
                            : StrokeStyle(
                                lineWidth: 1.7,
                                lineCap: .round,
                                lineJoin: .round
                            )
                    )
                    .interpolationMethod(segment.style == .noData ? .linear : .catmullRom)
                }
            }

            if let latest = model.renderedLineSamples.last,
               let projected = model.projectedChartPoint
            {
                LineMark(
                    x: .value("Estimated time", latest.timestamp),
                    y: .value("Estimated battery", latest.percentage),
                    series: .value("Series", "Forecast")
                )
                .foregroundStyle(lineColor(for: model.lineStyle(for: latest)))
                .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [4, 4]))

                LineMark(
                    x: .value("Estimated time", projected.timestamp),
                    y: .value("Estimated battery", projected.percentage),
                    series: .value("Series", "Forecast")
                )
                .foregroundStyle(lineColor(for: projected.style))
                .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round, dash: [4, 4]))
            }

            if let latest = model.renderedLineSamples.last {
                PointMark(
                    x: .value("Current time", latest.timestamp),
                    y: .value("Current battery", latest.percentage)
                )
                .symbolSize(48)
                .foregroundStyle(lineColor(for: model.lineStyle(for: latest)))
            }

            ForEach(model.chargingMarkerSamples, id: \.timestamp) { sample in
                PointMark(
                    x: .value("Charging section", sample.timestamp),
                    y: .value("Battery while charging", sample.percentage)
                )
                .symbol {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10.5, weight: .black))
                        .foregroundStyle(chartChargingColor)
                        .shadow(color: Color.white.opacity(0.95), radius: 1)
                        .shadow(color: Color.black.opacity(0.20), radius: 0.7, y: 0.7)
                }
            }

            if let hoveredPoint {
                RuleMark(x: .value("Selected time", hoveredPoint.timestamp))
                    .foregroundStyle(Color.secondary.opacity(0.50))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                PointMark(
                    x: .value("Selected time", hoveredPoint.timestamp),
                    y: .value("Selected battery", hoveredPoint.percentage)
                )
                .symbol {
                    DashboardHoverPulseSymbol(
                        color: lineColor(for: hoveredPoint.style),
                        reduceMotion: shouldReduceMotion
                    )
                }
            }
        }
        .chartXScale(domain: model.chartStart...model.chartEnd)
        .chartYScale(domain: model.chartYDomain)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { plotArea in
            plotArea.background(Color.clear)
        }
    }

    private var chartInteractionLayer: some View {
        Chart {
            PointMark(
                x: .value("Interaction start", model.chartStart),
                y: .value("Interaction minimum", model.chartYDomain.lowerBound)
            )
            .foregroundStyle(Color.clear)

            PointMark(
                x: .value("Interaction end", model.chartEnd),
                y: .value("Interaction maximum", model.chartYDomain.upperBound)
            )
            .foregroundStyle(Color.clear)
        }
        .chartXScale(domain: model.chartStart...model.chartEnd)
        .chartYScale(domain: model.chartYDomain)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartPlotStyle { plotArea in
            plotArea.background(Color.clear)
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                let plotFrame = geometry[proxy.plotAreaFrame]
                ZStack(alignment: .topLeading) {
                    DashboardHoverTrackingView(
                        onMove: { location in
                            guard revealProgress >= 0.999 else {
                                hoveredPoint = nil
                                return
                            }
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
                            guard let candidate = model.nearestChartPoint(to: date) else {
                                hoveredPoint = nil
                                return
                            }
                            guard hoveredPoint?.timestamp != candidate.timestamp else { return }
                            if let current = hoveredPoint,
                               let currentX = proxy.position(forX: current.timestamp),
                               let candidateX = proxy.position(forX: candidate.timestamp),
                               !DashboardHoverSelectionPolicy.shouldSwitch(
                                   currentX: currentX,
                                   candidateX: candidateX,
                                   pointerX: xPosition
                               )
                            {
                                return
                            }
                            hoveredPoint = candidate
                        },
                        onExit: {
                            hoveredPoint = nil
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    hoverAxisOverlay(proxy: proxy, plotFrame: plotFrame)

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
        .accessibilityHidden(true)
    }

    private func hoverAxisOverlay(proxy: ChartProxy, plotFrame: CGRect) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach([100, 50, 0], id: \.self) { percentage in
                if let relativeY = proxy.position(forY: Double(percentage)) {
                    hoverAxisLabel("\(percentage)%", size: 8)
                        .frame(width: 34, height: 10, alignment: .leading)
                        .position(
                            x: plotFrame.minX + 23,
                            y: yAxisLabelCenter(
                                for: percentage,
                                relativeY: relativeY,
                                plotFrame: plotFrame
                            )
                        )
                        .opacity(hoveredPoint == nil ? 0 : 1)
                }
            }

            ForEach(Array(model.hoverTimeAxisTicks.enumerated()), id: \.offset) { index, tick in
                if let relativeX = proxy.position(forX: tick.timestamp) {
                    let labelWidth = xAxisLabelWidth(for: tick.label)
                    hoverAxisLabel(
                        tick.label,
                        size: 8,
                        tracking: -0.10,
                        condensed: true,
                        foregroundOpacity: 0.92
                    )
                        .frame(
                            width: labelWidth,
                            height: 10,
                            alignment: xAxisLabelAlignment(
                                relativeX: relativeX,
                                plotFrame: plotFrame
                            )
                        )
                        .position(
                            x: xAxisLabelCenter(
                                relativeX: relativeX,
                                labelWidth: labelWidth,
                                plotFrame: plotFrame
                            ),
                            y: plotFrame.maxY - 8
                        )
                        .opacity(hoveredPoint == nil ? 0 : 1)
                }
            }
        }
        .animation(
            shouldReduceMotion ? nil : .easeOut(duration: 0.12),
            value: hoveredPoint != nil
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func hoverAxisLabel(
        _ text: String,
        size: CGFloat,
        tracking: CGFloat = 0,
        condensed: Bool = false,
        foregroundOpacity: Double = 0.82
    ) -> some View {
        Text(text)
            .font(.system(size: size, weight: .medium))
            .fontWidth(condensed ? .condensed : .standard)
            .tracking(tracking)
            .monospacedDigit()
            .foregroundStyle(Color.secondary.opacity(foregroundOpacity))
            .shadow(
                color: Color(nsColor: .windowBackgroundColor).opacity(0.96),
                radius: 1.15
            )
            .lineLimit(1)
            .fixedSize()
    }

    private func yAxisLabelCenter(
        for percentage: Int,
        relativeY: CGFloat,
        plotFrame: CGRect
    ) -> CGFloat {
        let absoluteY = plotFrame.minY + relativeY
        switch percentage {
        case 100:
            return absoluteY + 5
        case 0:
            return absoluteY - 11
        default:
            return absoluteY
        }
    }

    private func xAxisLabelWidth(for label: String) -> CGFloat {
        if label.contains(":") { return 34 }
        if label == "now" { return 30 }
        return 28
    }

    private func xAxisLabelAlignment(
        relativeX: CGFloat,
        plotFrame: CGRect
    ) -> Alignment {
        if relativeX <= 1 { return .leading }
        if relativeX >= plotFrame.width - 1 { return .trailing }
        return .center
    }

    private func xAxisLabelCenter(
        relativeX: CGFloat,
        labelWidth: CGFloat,
        plotFrame: CGRect
    ) -> CGFloat {
        let absoluteX = plotFrame.minX + relativeX
        if relativeX <= 1 {
            let leadingEdge = max(plotFrame.minX + 4, absoluteX)
            return leadingEdge + labelWidth / 2
        }
        if relativeX >= plotFrame.width - 1 {
            let trailingEdge = min(plotFrame.maxX - 4, absoluteX)
            return trailingEdge - labelWidth / 2
        }
        return absoluteX
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

    private func lineColor(for style: BatteryHistoryLineStyle) -> Color {
        switch style {
        case .charging:
            return chartChargingColor
        case .discharging:
            return chartDischargingColor
        case .connectedNotCharging:
            return .secondary
        case .noData:
            return .secondary.opacity(0.72)
        }
    }

    private var chartChargingColor: Color {
        Color(red: 0.02, green: 0.72, blue: 0.23)
    }

    private var chartDischargingColor: Color {
        Color(red: 0.96, green: 0.10, blue: 0.13)
    }

    private var chartGridStroke: StrokeStyle {
        StrokeStyle(lineWidth: 0.6, lineCap: .round, dash: [3, 5])
    }

    private var rangePickerAnimation: Animation {
        .interactiveSpring(response: 0.34, dampingFraction: 0.86, blendDuration: 0.12)
    }

    private func selectHistoryRange(_ range: BatteryHistoryRange) {
        withAnimation(rangePickerAnimation) {
            model.selectRange(range)
        }
    }

    private func startChartReveal() {
        hoveredPoint = nil
        guard !shouldReduceMotion else {
            revealProgress = 1
            return
        }

        revealProgress = 0
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.90)) {
                revealProgress = 1
            }
        }
    }

    private var shouldReduceMotion: Bool {
        reduceMotionOverride ?? reduceMotion
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
        HStack(spacing: 3) {
            Text(formattedPercentage(point.percentage))
                .font(.system(size: 11, weight: .semibold))
            Text("•")
                .font(.system(size: 10, weight: .semibold))
            Text(point.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 12, weight: .semibold))
        }
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
    fileprivate var axisFractions: [Double] {
        switch self {
        case .sevenDays:
            return (0...7).map { Double($0) / 7 }
        default:
            return (0...6).map { Double($0) / 6 }
        }
    }

    fileprivate var referenceAxisLabels: [String] {
        switch self {
        case .thirtyMinutes:
            return ["30m", "25m", "20m", "15m", "10m", "5m", "now"]
        case .oneHour:
            return ["1h", "50m", "40m", "30m", "20m", "10m", "now"]
        case .oneDay:
            return ["24h", "20h", "16h", "12h", "8h", "4h", "now"]
        case .sevenDays:
            return ["7d", "6d", "5d", "4d", "3d", "2d", "1d", "now"]
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

    fileprivate var accessibilityTitle: String {
        switch self {
        case .thirtyMinutes: return "the last 30 minutes"
        case .oneHour: return "the last hour"
        case .oneDay: return "the last day"
        case .sevenDays: return "the last week"
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
