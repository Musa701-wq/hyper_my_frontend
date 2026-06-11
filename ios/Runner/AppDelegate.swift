import Flutter
import UIKit
import AppTrackingTransparency

@main
@objc class AppDelegate: FlutterAppDelegate {

  private var attResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "custom_att",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] (call, result) in
        if call.method == "requestAtt" {
          self?.requestAtt(result: result)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func requestAtt(result: @escaping FlutterResult) {
    guard #available(iOS 14, *) else {
      result(4) // notSupported
      return
    }

    let status = ATTrackingManager.trackingAuthorizationStatus
    guard status == .notDetermined else {
      result(Int(status.rawValue))
      return
    }

    ATTrackingManager.requestTrackingAuthorization { [weak self] status in
      if status == .notDetermined {
        // Another system dialog (e.g. local network) was blocking.
        // Retry when the app becomes active again.
        self?.attResult = result
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(self?.retryAtt),
          name: UIApplication.didBecomeActiveNotification,
          object: nil
        )
      } else {
        result(Int(status.rawValue))
      }
    }
  }

  @objc private func retryAtt() {
    NotificationCenter.default.removeObserver(
      self,
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    guard #available(iOS 14, *) else { return }
    ATTrackingManager.requestTrackingAuthorization { [weak self] status in
      self?.attResult?(Int(status.rawValue))
      self?.attResult = nil
    }
  }
}
