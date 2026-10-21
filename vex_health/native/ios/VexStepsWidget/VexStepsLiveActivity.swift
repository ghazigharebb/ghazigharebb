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
                    VexRing(pct: s.pct, done: s.done).frame(width: 46, height: 46).padding(.leading, 2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(VexShared.fmt(s.steps))
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.7)
                        Text("هەنگاو").font(.system(size: 12, weight: .semibold)).foregroundColor(VexColor.mute)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 7) {
                        HStack(spacing: 16) {
                            VexChip(icon: "point.topleft.down.curvedto.point.bottomright.up", color: VexColor.cy,
                                    text: String(format: "%.2f km", s.km))
                            VexChip(icon: "flame.fill", color: VexColor.flame, text: "\(s.kcal) kcal")
                            if s.hr >= 30 && s.hr <= 220 {
                                VexChip(icon: "heart.fill", color: VexColor.heart, text: "\(s.hr)")
                            }
                        }
                        VexTrack(pct: s.pct, done: s.done)
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
        HStack(alignment: .center, spacing: 14) {
            VexRing(pct: s.pct, done: s.done, line: 6).frame(width: 54, height: 54)
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(VexShared.fmt(s.steps))
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("هەنگاو").font(.system(size: 13, weight: .semibold)).foregroundColor(VexColor.mute)
                    Spacer(minLength: 0)
                    Text("VEX").font(.system(size: 11, weight: .heavy, design: .rounded)).foregroundColor(VexColor.cy)
                }
                HStack(spacing: 14) {
                    VexChip(icon: "point.topleft.down.curvedto.point.bottomright.up", color: VexColor.cy,
                            text: String(format: "%.2f km", s.km))
                    VexChip(icon: "flame.fill", color: VexColor.flame, text: "\(s.kcal) kcal")
                    if s.hr >= 30 && s.hr <= 220 {
                        VexChip(icon: "heart.fill", color: VexColor.heart, text: "\(s.hr)")
                    }
                }
                VexTrack(pct: s.pct, done: s.done)
                Text(vexRemaining(s))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(VexColor.mute)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(14)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
