import Flutter
import UIKit
import CoreMotion

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let motionManager = CMMotionManager()
  private var currentAngle: Double = 0.0

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "jjibudung/posture_service",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }

        switch call.method {
        case "ping":
          result("pong")

        case "start":
          self.startMotionUpdates()
          result(true)

        case "stop":
          self.motionManager.stopDeviceMotionUpdates()
          result(true)

        case "getCurrentAngle":
          result(self.currentAngle)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func startMotionUpdates() {
    guard motionManager.isDeviceMotionAvailable else { return }

    motionManager.deviceMotionUpdateInterval = 0.2

    motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
      guard let self = self, let motion = motion else { return }
      // Pitch, matching the Android rotation-vector angle calculation.
      self.currentAngle = motion.attitude.pitch * 180 / Double.pi
    }
  }
}
