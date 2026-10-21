// VEX Health — هاوبەش لە نێوان ئەپ (Runner) و Widget Extension
// ⚠️ ئەم فایلە دەبێت لە Target Membership ـی هەردوو Target ـدا بێت: Runner و VexStepsWidget
import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

enum VexShared {
    /// ⚠️ بیگۆڕە بۆ App Group ـی خۆت: group.<Bundle Identifier>   (بڕوانە NOTIFICATIONS.md)
    static let appGroup = "group.com.example.vexHealth"

    static let kSteps = "vex_steps"
    static let kGoal = "vex_goal"
    static let kKm = "vex_km"
    static let kKcal = "vex_kcal"
    static let kHr = "vex_hr"
    static let kStamp = "vex_stamp"

    static func fmt(_ n: Int) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US")
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    /// 13635 → «13.6k»  (بۆ شوێنی بچووکی Dynamic Island)
    static func short(_ n: Int) -> String {
        if n < 10_000 { return fmt(n) }
        return String(format: "%.1fk", Double(n) / 1000.0)
    }
}

struct VexMetrics: Codable, Hashable {
    var steps: Int
    var goal: Int
    var km: Double
    var kcal: Int
    var hr: Int
    var remKm: Double
    var remMin: Int

    var pct: Double { min(1.0, Double(steps) / Double(max(goal, 1))) }
    var done: Bool { steps >= goal }

    /// هەمان فۆرمولەی Android و وێبەکە: هەنگاو = 0.415 × باڵا، kcal = km × کێش × 0.63، 105 هەنگاو لە خولەکێکدا
    static func make(steps: Int, goal: Int, heightCm: Int, weightKg: Int, hr: Int) -> VexMetrics {
        let h = Double(min(max(heightCm, 100), 250))
        let w = Double(min(max(weightKg, 25), 250))
        let stride = 0.415 * h / 100.0
        let km = Double(steps) * stride / 1000.0
        let kcal = Int((km * w * 0.63).rounded(.down))
        let rem = max(0, goal - steps)
        return VexMetrics(
            steps: steps, goal: goal, km: km, kcal: kcal, hr: hr,
            remKm: Double(rem) * stride / 1000.0,
            remMin: Int((Double(rem) / 105.0).rounded(.up))
        )
    }
}

#if canImport(ActivityKit)
@available(iOS 16.1, *)
struct VexStepsAttributes: ActivityAttributes {
    public typealias ContentState = VexMetrics
    var name: String
}
#endif
