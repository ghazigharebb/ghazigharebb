// VEX Health — Widget ی شاشەی سەرەکی + شاشەی قفڵ (iOS 16+)
import SwiftUI
import WidgetKit

struct VexEntry: TimelineEntry {
    let date: Date
    let m: VexMetrics
}

struct VexProvider: TimelineProvider {
    private func load() -> VexMetrics {
        let d = UserDefaults(suiteName: VexShared.appGroup)
        let goal = d?.integer(forKey: VexShared.kGoal) ?? 0
        return VexMetrics(
            steps: d?.integer(forKey: VexShared.kSteps) ?? 0,
            goal: goal > 0 ? goal : 10000,
            km: d?.double(forKey: VexShared.kKm) ?? 0,
            kcal: d?.integer(forKey: VexShared.kKcal) ?? 0,
            hr: d?.integer(forKey: VexShared.kHr) ?? 0,
            remKm: 0, remMin: 0
        )
    }

    func placeholder(in context: Context) -> VexEntry {
        VexEntry(date: Date(), m: VexMetrics.make(steps: 6420, goal: 10000, heightCm: 175, weightKg: 75, hr: 72))
    }

    func getSnapshot(in context: Context, completion: @escaping (VexEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : VexEntry(date: Date(), m: load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VexEntry>) -> Void) {
        let e = VexEntry(date: Date(), m: load())
        completion(Timeline(entries: [e], policy: .after(Date().addingTimeInterval(15 * 60))))
    }
}

struct VexWidgetView: View {
    @Environment(\.widgetFamily) var family
    let e: VexEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: e.m.pct) {
                Image(systemName: "figure.walk")
            } currentValueLabel: {
                Text(VexShared.short(e.m.steps)).font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                    Text("\(VexShared.fmt(e.m.steps)) هەنگاو").font(.system(size: 14, weight: .bold))
                }
                ProgressView(value: e.m.pct)
                Text(e.m.done ? "ئامانج تەواو بوو" : "ماوە \(VexShared.fmt(max(0, e.m.goal - e.m.steps)))")
                    .font(.system(size: 11))
            }
        case .accessoryInline:
            Text("🚶 \(VexShared.fmt(e.m.steps)) / \(VexShared.fmt(e.m.goal))")
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VexRing(pct: e.m.pct, done: e.m.done, line: 5).frame(width: 46, height: 46)
                    Spacer()
                }
                Text(VexShared.fmt(e.m.steps))
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.7)
                Text("هەنگاو · \(String(format: "%.1f", e.m.km)) km")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(VexColor.mute)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

struct VexStepsHomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "VexStepsHomeWidget", provider: VexProvider()) { entry in
            if #available(iOS 17.0, *) {
                VexWidgetView(e: entry).containerBackground(VexColor.bg, for: .widget)
            } else {
                VexWidgetView(e: entry).padding().background(VexColor.bg)
            }
        }
        .configurationDisplayName("هەنگاوەکان")
        .description("هەنگاو و ئامانجی ڕۆژانە")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
