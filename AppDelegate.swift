import UserNotifications
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // ---- VexSteps ----
    if let r = engineBridge.pluginRegistry.registrar(forPlugin: "VexStepsBridge") {
      StepsBridge.shared.register(with: r.messenger())
    }
    // ---- VexAlerts (flutter_local_notifications) ----
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
  }
}
