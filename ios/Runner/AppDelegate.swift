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

    let appIconChannel = FlutterMethodChannel(
      name: "notion_book_library/app_icon",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    appIconChannel.setMethodCallHandler { call, result in
      guard call.method == "setAlternateIconName" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard UIApplication.shared.supportsAlternateIcons else {
        result(FlutterError(code: "UNSUPPORTED", message: "Alternate icons not supported", details: nil))
        return
      }
      let name = call.arguments as? String
      UIApplication.shared.setAlternateIconName(name) { error in
        if let error = error {
          result(FlutterError(code: "SET_FAILED", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    }
  }
}
