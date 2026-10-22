// VEX Health — پردی Flutter ↔ iOS (Live Activity + Dynamic Island + Widget)
// کەناڵی: vex/steps   |   پێویستی بە iOS 16.2+ بۆ Live Activity هەیە (لە iOS کۆنتر هیچ ناکات)
import Flutter
import UIKit
import CoreMotion
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif

final class StepsBridge: NSObject {
    static let shared = StepsBridge()

    private var channel: FlutterMethodChannel?
    private let pedo = CMPedometer()
    private var pedoOn = false

    private var enabled = false
    private var phoneToday = 0          // هەنگاوی ئەمڕۆی مۆبایل (CMPedometer)
    private var pushSteps = 0           // داتای Band کە Flutter ناردوویەتی
    private var pushPhone = 0
    private var pushDay = ""
    private var trackedDay = ""
    private var goal = 10000
    private var heightCm = 170
    private var weightKg = 70
    private var hr = 0

    private var lastUI = Date.distantPast
    private var lastWidget = Date.distantPast
    private var tokenWatched = Set<String>()

    func register(with messenger: FlutterBinaryMessenger) {
        let ch = FlutterMethodChannel(name: "vex/steps", binaryMessenger: messenger)
        channel = ch
        ch.setMethodCallHandler { [weak self] call, result in self?.handle(call, result) }
    }

    // MARK: - Flutter calls
    private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            apply(call.arguments)
            guard #available(iOS 16.2, *) else {
                result(FlutterError(code: "unsupported", message: "Live Activity پێویستی بە iOS 16.2 یان نوێتر هەیە", details: nil))
                return
            }
            #if canImport(ActivityKit)
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                result(FlutterError(code: "disabled", message: "Live Activities لە ڕێکخستنەکانی iPhone کوژاوەتەوە (Settings ‹ VEX Health)", details: nil))
                return
            }
            #endif
            enabled = true
            startPedometer()
            render(force: true)
            result(true)
        case "update":
            apply(call.arguments)
            if enabled { render(force: true) }
            result(true)
        case "stop":
            enabled = false
            stopPedometer()
            endActivity()
            result(true)
        case "takeWater":
            result(0)   // دوگمەی ئاو تەنها لە Android هەیە
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func apply(_ args: Any?) {
        guard let m = args as? [String: Any] else { return }
        if let g = (m["goal"] as? NSNumber)?.intValue { goal = max(1, g) }
        if let h = (m["heightCm"] as? NSNumber)?.intValue { heightCm = h }
        if let w = (m["weightKg"] as? NSNumber)?.intValue { weightKg = w }
        if let r = (m["hr"] as? NSNumber)?.intValue { hr = r }
        if let s = (m["steps"] as? NSNumber)?.intValue {
            pushSteps = s
            pushDay = (m["day"] as? String) ?? dayKey()
            pushPhone = phoneToday
        }
    }

    // MARK: - هەنگاوی مۆبایل
    private func dayKey() -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    private func startPedometer() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedo.stopUpdates()
        trackedDay = dayKey()
        pedoOn = true
        pedo.startUpdates(from: Calendar.current.startOfDay(for: Date())) { [weak self] data, _ in
            guard let self = self, let d = data else { return }
            DispatchQueue.main.async {
                self.phoneToday = d.numberOfSteps.intValue
                if self.enabled { self.render(force: false) }
            }
        }
    }

    private func stopPedometer() {
        pedo.stopUpdates()
        pedoOn = false
    }

    private func currentSteps() -> Int {
        guard pushDay == dayKey() else { return phoneToday }
        return max(0, pushSteps + max(0, phoneToday - pushPhone))
    }

    // MARK: - نیشاندان
    private func render(force: Bool) {
        // ڕۆژی نوێ: پێدۆمەتر لە سەرەتای ڕۆژەکەوە دووبارە دەست پێدەکات
        if pedoOn && trackedDay != dayKey() {
            phoneToday = 0
            pushPhone = 0
            startPedometer()
        }
        let now = Date()
        if !force && now.timeIntervalSince(lastUI) < 2 { return }
        lastUI = now

        let st = VexMetrics.make(steps: currentSteps(), goal: goal, heightCm: heightCm, weightKg: weightKg, hr: hr)
        saveForWidget(st)
        if #available(iOS 16.2, *) { updateActivity(st) }
    }

    private func saveForWidget(_ s: VexMetrics) {
        guard let d = UserDefaults(suiteName: VexShared.appGroup) else { return }
        d.set(s.steps, forKey: VexShared.kSteps)
        d.set(s.goal, forKey: VexShared.kGoal)
        d.set(s.km, forKey: VexShared.kKm)
        d.set(s.kcal, forKey: VexShared.kKcal)
        d.set(s.hr, forKey: VexShared.kHr)
        d.set(Date().timeIntervalSince1970, forKey: VexShared.kStamp)
        // سیستەم ژمارەی نوێکردنەوەی Widget سنووردار دەکات؛ دەقیقەیەک جار بەسە
        if Date().timeIntervalSince(lastWidget) > 60 {
            lastWidget = Date()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    @available(iOS 16.2, *)
    private func updateActivity(_ st: VexMetrics) {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let content = ActivityContent(state: st, staleDate: nil)
        if let a = Activity<VexStepsAttributes>.activities.first {
            watchToken(a)
            Task { await a.update(content) }
        } else {
            do {
                let a = try Activity<VexStepsAttributes>.request(
                    attributes: VexStepsAttributes(name: "VEX"),
                    content: content,
                    pushType: .token
                )
                watchToken(a)
            } catch {
                // نموونە: ژمارەی Live Activity ـەکان زۆرە — بەبێ هەڵە تێدەپەڕێت
            }
        }
        #endif
    }

    @available(iOS 16.2, *)
    private func watchToken(_ a: Activity<VexStepsAttributes>) {
        #if canImport(ActivityKit)
        guard !tokenWatched.contains(a.id) else { return }
        tokenWatched.insert(a.id)
        Task { [weak self] in
            for await data in a.pushTokenUpdates {
                let hex = data.map { String(format: "%02x", $0) }.joined()
                DispatchQueue.main.async { self?.channel?.invokeMethod("pushToken", arguments: hex) }
            }
        }
        #endif
    }

    private func endActivity() {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            for a in Activity<VexStepsAttributes>.activities {
                Task { await a.end(nil, dismissalPolicy: .immediate) }
            }
        }
        #endif
    }
}
