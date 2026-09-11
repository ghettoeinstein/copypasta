import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Must match the App Group added under Signing & Capabilities for both
  /// the Runner target and the CopyPastaKeyboard extension target.
  static let appGroupID = "group.com.calebpierre.copypasta"
  static let clipsKey = "clips_json"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.calebpierre.copypasta/clip_bridge",
      binaryMessenger: engineBridge.pluginRegistry as! FlutterBinaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "syncClips",
            let args = call.arguments as? [String: Any],
            let json = args["json"] as? String,
            let defaults = UserDefaults(suiteName: AppDelegate.appGroupID) else {
        result(FlutterMethodNotImplemented)
        return
      }
      defaults.set(json, forKey: AppDelegate.clipsKey)
      result(nil)
    }
  }
}
