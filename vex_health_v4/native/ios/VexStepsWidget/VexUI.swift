// VEX Health — پارچە هاوبەشەکانی دیزاین (هەمان ڕەنگ و شێوەی وێبەکە)
import SwiftUI

enum VexColor {
    static let bg = Color(red: 0.016, green: 0.102, blue: 0.133)      // #041A22
    static let cy = Color(red: 0.184, green: 0.902, blue: 0.953)      // #2FE6F3
    static let mint = Color(red: 0.235, green: 0.941, blue: 0.541)    // #3CF08A
    static let flame = Color(red: 1.0, green: 0.541, blue: 0.361)     // #FF8A5C
    static let mute = Color(red: 0.549, green: 0.718, blue: 0.749)    // #8CB7BF
    static let heart = Color(red: 1.0, green: 0.361, blue: 0.478)     // #FF5C7A
}

/// بازنەی پێشکەوتن؛ لە کاتی تەواوبوونی ئامانج ✓ ی سەوز
struct VexRing: View {
    let pct: Double
    let done: Bool
    var line: CGFloat = 5

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.12), lineWidth: line)
            Circle()
                .trim(from: 0, to: CGFloat(max(0.001, pct)))
                .stroke(
                    done ? AnyShapeStyle(VexColor.mint)
                         : AnyShapeStyle(LinearGradient(colors: [VexColor.cy, VexColor.mint], startPoint: .top, endPoint: .bottom)),
                    style: StrokeStyle(lineWidth: line, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            if done {
                Image(systemName: "checkmark").font(.system(size: 14, weight: .heavy)).foregroundColor(VexColor.mint)
            } else {
                Text("\(Int((pct * 100).rounded()))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)
            }
        }
    }
}

/// ڕێگای ئامانج: کەسێک لە ڕاستەوە بەرەو ئاڵا (لای چەپ) دەڕوات.
/// لە کاتی تەواوبوون لە تەنیشت ئاڵاکە دەوەستێت و بەسەریدا نانیشێت.
struct VexTrack: View {
    let pct: Double
    let done: Bool

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let lineW = max(0, w - 14)
            let fillW = lineW * CGFloat(min(1, max(0, pct)))
            let walkerX = done ? CGFloat(30) : max(CGFloat(18), w - fillW)
            ZStack(alignment: .topLeading) {
                // هێڵی خاڵخاڵ
                Path { p in
                    p.move(to: CGPoint(x: 14, y: 13))
                    p.addLine(to: CGPoint(x: w, y: 13))
                }
                .stroke(Color.white.opacity(0.22), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 3]))
                // هێڵی تەواوبوو
                Capsule()
                    .fill(LinearGradient(colors: [VexColor.mint, VexColor.cy], startPoint: .leading, endPoint: .trailing))
                    .frame(width: fillW, height: 2)
                    .offset(x: w - fillW, y: 12)
                // ئاڵا
                Image(systemName: "flag.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(done ? .white : VexColor.mint)
                    .shadow(color: done ? VexColor.mint : .clear, radius: 4)
                    .offset(x: 0, y: 1)
                // کەسی ڕۆیشتوو (scaleX(-1) بۆ ئەوەی بەرەو ئاڵا بڕوات)
                Image(systemName: "figure.walk")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .scaleEffect(x: -1, y: 1)
                    .shadow(color: VexColor.cy.opacity(0.7), radius: 3)
                    .position(x: walkerX, y: 8)
            }
        }
        .frame(height: 20)
        .environment(\.layoutDirection, .leftToRight)
    }
}

struct VexChip: View {
    let icon: String
    let color: Color
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 11, weight: .bold)).foregroundColor(color)
            Text(text).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white)
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

func vexRemaining(_ s: VexMetrics) -> String {
    if s.done { return "🎉 ئامانجی ئەمڕۆ تەواو بوو" }
    return "ماوە \(VexShared.fmt(max(0, s.goal - s.steps))) هەنگاو · \(String(format: "%.1f", s.remKm)) km · نزیکەی \(s.remMin) خولەک"
}
