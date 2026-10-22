// VEX Health — بخەرە ناو ios/Runner/AppDelegate.swift
// تەنها ئەم 3 دێڕەی «VexSteps» زیاد بکە لە ناو didFinishLaunchingWithOptions، دوای GeneratedPluginRegistrant.register
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        // ---- VexSteps ----
        if let r = self.registrar(forPlugin: "VexStepsBridge") {
            StepsBridge.shared.register(with: r.messenger())
        }
        // ---- VexAlerts (flutter_local_notifications) ----
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
        }
        // ------------------
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
