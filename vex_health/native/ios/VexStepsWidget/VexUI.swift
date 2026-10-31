// VEX Health — پارچە هاوبەشەکانی دیزاینی «گەشت» (هەمان دیزاینی Android)
import SwiftUI

enum VexColor {
    static let bg = Color(red: 0.055, green: 0.110, blue: 0.133)      // #0E1C22
    static let cy = Color(red: 0.184, green: 0.902, blue: 0.953)      // #2FE6F3
    static let mint = Color(red: 0.235, green: 0.941, blue: 0.541)    // #3CF08A
    static let sky = Color(red: 0.498, green: 0.847, blue: 1.0)       // #7FD8FF
    static let violet = Color(red: 0.831, green: 0.788, blue: 1.0)    // #D4C9FF
    static let flame = Color(red: 1.0, green: 0.604, blue: 0.361)     // #FF9A5C
    static let heart = Color(red: 1.0, green: 0.435, blue: 0.525)     // #FF6F86
    static let mute = Color(red: 0.624, green: 0.718, blue: 0.741)    // #9FB7BD
    static let accent = LinearGradient(colors: [cy, mint], startPoint: .topLeading, endPoint: .bottomTrailing)
}

/// ژمارەی هەنگاو « 1,456 / 10,000 »
struct VexHero: View {
    let s: VexMetrics
    var size: CGFloat = 34
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(VexShared.fmt(s.steps))
                .font(.system(size: size, weight: .heavy, design: .rounded))
                .foregroundColor(s.done ? VexColor.mint : .white)
            Text("/ \(VexShared.fmt(s.goal))")
                .font(.system(size: size * 0.38, weight: .medium, design: .rounded))
                .foregroundColor(VexColor.mute)
        }
        .environment(\.layoutDirection, .leftToRight)
        .minimumScaleFactor(0.7)
        .lineLimit(1)
    }
}

/// ڕێگای گەشت: ماڵ (ڕاست) ← ڕاکەر ← ئاڵا (چەپ)، خاڵەکانی 25/50/75٪
struct VexTrack: View {
    let s: VexMetrics
    var showScale = false

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { g in
                let w = g.size.width
                let cy: CGFloat = 17
                let xHome = w - 12
                let xFlag: CGFloat = 12
                let l = xFlag + 12
                let r = xHome - 12
                let p = CGFloat(min(1, max(0, s.pct)))
                let xRun = s.done ? xFlag + 20 : r - (r - l) * p
                ZStack {
                    // هێڵی خاڵخاڵ
                    Path { pth in pth.move(to: CGPoint(x: l, y: cy)); pth.addLine(to: CGPoint(x: r, y: cy)) }
                        .stroke(Color.white.opacity(0.22), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 3]))
                    // هێڵی تەواوبوو
                    if p > 0 {
                        Capsule()
                            .fill(LinearGradient(colors: [VexColor.mint, VexColor.cy], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, r - xRun), height: 4)
                            .shadow(color: VexColor.mint.opacity(0.45), radius: 4)
                            .position(x: (xRun + r) / 2, y: cy)
                    }
                    // خاڵەکان
                    ForEach([25, 50, 75], id: \.self) { m in
                        let x = r - (r - l) * CGFloat(m) / 100
                        let passed = s.pct * 100 >= Double(m)
                        Circle()
                            .fill(passed ? VexColor.mint : Color(red: 0.094, green: 0.196, blue: 0.227))
                            .frame(width: passed ? 10 : 8, height: passed ? 10 : 8)
                            .overlay(Circle().stroke(passed ? VexColor.mint.opacity(0.3) : Color.white.opacity(0.22), lineWidth: 2))
                            .position(x: x, y: cy)
                    }
                    // ماڵ
                    Circle().fill(Color(red: 0.114, green: 0.212, blue: 0.243)).frame(width: 24, height: 24)
                        .overlay(Image(systemName: "house.fill").font(.system(size: 11, weight: .bold)).foregroundColor(VexColor.mute))
                        .position(x: xHome, y: cy)
                    // ئاڵا
                    Circle().fill(VexColor.mint.opacity(0.16)).frame(width: 24, height: 24)
                        .overlay(Circle().stroke(VexColor.mint.opacity(0.35), lineWidth: 1))
                        .overlay(Image(systemName: "flag.fill").font(.system(size: 11, weight: .bold)).foregroundColor(VexColor.mint))
                        .position(x: xFlag, y: cy)
                    // ڕاکەر
                    Circle().fill(RadialGradient(colors: [VexColor.cy.opacity(0.35), VexColor.cy.opacity(0)], center: .center, startRadius: 0, endRadius: 19))
                        .frame(width: 38, height: 38).position(x: xRun, y: cy)
                    Circle().fill(VexColor.accent).frame(width: 26, height: 26)
                        .overlay(Circle().stroke(VexColor.bg, lineWidth: 2.5))
                        .overlay(Image(systemName: "figure.walk").font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.016, green: 0.196, blue: 0.227)).scaleEffect(x: -1, y: 1))
                        .shadow(color: VexColor.cy.opacity(0.45), radius: 6, y: 3)
                        .position(x: xRun, y: cy)
                }
            }
            .frame(height: 34)
            if showScale {
                HStack {
                    ForEach(Array(["10k", "7.5k", "5k", "2.5k", "0"].enumerated()), id: \.offset) { i, t in
                        if i > 0 { Spacer() }
                        Text(t).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundColor(VexColor.mute)
                    }
                }
                .padding(.horizontal, 10)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

/// حەبەی ڕەنگاوڕەنگ (ماوە · کم · خولەک)
struct VexPill: View {
    let icon: String
    let color: Color
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10, weight: .bold))
            Text(text).font(.system(size: 12, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 9).padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.14)))
    }
}

/// پێوانەی بچووک (کم · kcal · bpm)
struct VexChip: View {
    let icon: String
    let color: Color
    let text: String
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundColor(color)
            Text(text).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white)
        }
    }
}

func vexRemaining(_ s: VexMetrics) -> String {
    if s.done { return "ئامانجی ئەمڕۆ تەواو بوو" }
    return "ماوە \(VexShared.fmt(max(0, s.goal - s.steps))) هەنگاو · \(String(format: "%.1f", s.remKm)) کم · نزیکەی \(s.remMin) خولەک"
}
