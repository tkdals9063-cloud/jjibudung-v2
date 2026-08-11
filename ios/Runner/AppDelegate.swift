import Flutter
import UIKit
import CoreMotion

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let motionManager = CMMotionManager()
  private var currentAngle: Double = 0.0

  private var baselineAngle: Double = 0.0
  private var angleThreshold: Double = 15.0
  private var isSessionRunning = false
  private var sessionStartTime: Date?
  private var badPostureSeconds: TimeInterval = 0
  private var lastAccountingTime: Date?
  private var accountingTimer: Timer?

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
          let args = call.arguments as? [String: Any]
          self.startSession(
            baselineAngle: args?["baselineAngle"] as? Double ?? 0.0,
            angleThreshold: args?["angleThreshold"] as? Double ?? 15.0
          )
          result(true)

        case "stop":
          self.stopSession()
          result(true)

        case "getCurrentAngle":
          result(self.currentAngle)

        case "getSessionData":
          result(self.sessionData())

        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let streamChannel = FlutterEventChannel(
        name: "jjibudung/posture_stream",
        binaryMessenger: controller.binaryMessenger
      )
      streamChannel.setStreamHandler(self)
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

  private func isBadPosture() -> Bool {
    return abs(currentAngle - baselineAngle) > angleThreshold
  }

  private func accountElapsed() {
    guard isSessionRunning, let last = lastAccountingTime else { return }

    let now = Date()
    let elapsed = now.timeIntervalSince(last)
    if elapsed > 0 && isBadPosture() {
      badPostureSeconds += elapsed
    }
    lastAccountingTime = now
  }

  private func startSession(baselineAngle: Double, angleThreshold: Double) {
    self.baselineAngle = baselineAngle
    self.angleThreshold = angleThreshold
    self.isSessionRunning = true
    self.sessionStartTime = Date()
    self.lastAccountingTime = Date()
    self.badPostureSeconds = 0

    startMotionUpdates()

    accountingTimer?.invalidate()
    accountingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.accountElapsed()
    }
  }

  private func stopSession() {
    accountElapsed()
    isSessionRunning = false
    accountingTimer?.invalidate()
    accountingTimer = nil
    motionManager.stopDeviceMotionUpdates()
  }

  private func sessionData() -> [String: Any] {
    guard let start = sessionStartTime else {
      return [
        "totalSeconds": 0,
        "badSeconds": 0,
        "goodSeconds": 0,
        "postureRate": 100.0,
        "currentAngle": currentAngle,
        "baselineAngle": baselineAngle,
        "isBadPosture": false,
        "isRunning": false,
      ]
    }

    accountElapsed()

    let totalSeconds = max(0, Int(Date().timeIntervalSince(start)))
    let badSeconds = min(totalSeconds, Int(badPostureSeconds))
    let goodSeconds = max(0, totalSeconds - badSeconds)
    let postureRate = totalSeconds == 0
      ? 100.0
      : Double(goodSeconds) / Double(totalSeconds) * 100.0

    return [
      "totalSeconds": totalSeconds,
      "badSeconds": badSeconds,
      "goodSeconds": goodSeconds,
      "postureRate": postureRate,
      "currentAngle": currentAngle,
      "baselineAngle": baselineAngle,
      "isBadPosture": isBadPosture(),
      "isRunning": isSessionRunning,
    ]
  }
}

extension AppDelegate: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
    guard motionManager.isDeviceMotionAvailable else { return nil }

    motionManager.deviceMotionUpdateInterval = 0.1

    motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
      guard let self = self, let motion = motion else { return }
      let angle = motion.attitude.pitch * 180 / Double.pi
      self.currentAngle = angle
      eventSink(angle)
    }

    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    motionManager.stopDeviceMotionUpdates()
    return nil
  }
}
