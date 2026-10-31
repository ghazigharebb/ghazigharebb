// VEX Health — Live Activity (شاشەی قفڵ) + Dynamic Island
import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
struct VexStepsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VexStepsAttributes.self) { context in
            VexLockView(s: context.state)
                .activityBackgroundTint(VexColor.bg)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let s = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int((s.pct * 100).rounded()))%")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(s.done ? VexColor.mint : VexColor.cy)
                        Text("هەنگاو").font(.system(size: 11, weight: .semibold)).foregroundColor(VexColor.mute)
                    }.padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VexHero(s: s, size: 26).padding(.trailing, 2)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        VexTrack(s: s)
                        HStack(spacing: 14) {
                            VexChip(icon: "point.topleft.down.to.point.bottomright.curvepath.fill", color: VexColor.sky, text: String(format: "%.2f کم", s.km))
                            VexChip(icon: "flame.fill", color: VexColor.flame, text: "\(s.kcal) kcal")
                            if s.hr >= 30 && s.hr <= 220 {
                                VexChip(icon: "heart.fill", color: VexColor.heart, text: "\(s.hr) bpm")
                            }
                        }
                        Text(vexRemaining(s))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(VexColor.mute)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.top, 2)
                }
            } compactLeading: {
                Image(systemName: s.done ? "checkmark.circle.fill" : "figure.walk")
                    .foregroundColor(s.done ? VexColor.mint : VexColor.cy)
            } compactTrailing: {
                Text(VexShared.short(s.steps))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: 52)
                    .minimumScaleFactor(0.7)
            } minimal: {
                Image(systemName: s.done ? "checkmark.circle.fill" : "figure.walk")
                    .foregroundColor(s.done ? VexColor.mint : VexColor.cy)
            }
            .keylineTint(VexColor.cy)
        }
    }
}

@available(iOS 16.2, *)
struct VexLockView: View {
    let s: VexMetrics
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(s.done ? "گەشتی ئەمڕۆ تەواو بوو" : "گەشتی ئەمڕۆ بۆ ئامانج")
                .font(.system(size: 12, weight: .medium)).foregroundColor(VexColor.mute)
            HStack(alignment: .center) {
                VexHero(s: s, size: 32)
                Spacer()
                Text("\(Int((s.pct * 100).rounded()))%")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(s.done ? VexColor.mint : VexColor.cy)
            }
            VexTrack(s: s, showScale: true)
            HStack(spacing: 6) {
                if s.done {
                    VexPill(icon: "checkmark", color: VexColor.mint, text: "ئامانجی ئەمڕۆ تەواو بوو")
                } else {
                    VexPill(icon: "flag.fill", color: Color(red: 0.624, green: 0.965, blue: 0.984), text: "ماوە \(VexShared.fmt(max(0, s.goal - s.steps)))")
                    VexPill(icon: "point.topleft.down.to.point.bottomright.curvepath.fill", color: Color(red: 0.714, green: 0.910, blue: 1.0), text: String(format: "%.1f کم", s.remKm))
                    VexPill(icon: "clock.fill", color: VexColor.violet, text: "\(s.remMin) خولەک")
                }
            }
            HStack(spacing: 14) {
                VexChip(icon: "point.topleft.down.to.point.bottomright.curvepath.fill", color: VexColor.sky, text: String(format: "%.2f کم", s.km))
                VexChip(icon: "flame.fill", color: VexColor.flame, text: "\(s.kcal) kcal")
                if s.hr >= 30 && s.hr <= 220 {
                    VexChip(icon: "heart.fill", color: VexColor.heart, text: "\(s.hr) bpm")
                }
            }
        }
        .padding(14)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
