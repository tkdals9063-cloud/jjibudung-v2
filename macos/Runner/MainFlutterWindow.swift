import Cocoa
import FlutterMacOS

// macOS has no public accelerometer/tilt API. Sends a single stub reading
// on listen so callers averaging the stream (e.g. calibration) don't
// operate on an empty list.
class PostureStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
    eventSink(0.0)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}

class MainFlutterWindow: NSWindow {
  private let postureStreamHandler = PostureStreamHandler()

  // macOS has no public accelerometer/tilt API, so angle/bad-posture data
  // stays fixed at stub values, but elapsed time is tracked for real so the
  // timer in WorkScreen visibly counts up during desktop testing.
  private var sessionStartTime: Date?
  private var isSessionRunning = false

  private func sessionData() -> [String: Any] {
    guard let start = sessionStartTime else {
      return [
        "totalSeconds": 0,
        "badSeconds": 0,
        "goodSeconds": 0,
        "postureRate": 100.0,
        "currentAngle": 0.0,
        "baselineAngle": 0.0,
        "isBadPosture": false,
        "isRunning": false,
      ]
    }

    let totalSeconds = max(0, Int(Date().timeIntervalSince(start)))

    return [
      "totalSeconds": totalSeconds,
      "badSeconds": 0,
      "goodSeconds": totalSeconds,
      "postureRate": 100.0,
      "currentAngle": 0.0,
      "baselineAngle": 0.0,
      "isBadPosture": false,
      "isRunning": isSessionRunning,
    ]
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // macOS has no public accelerometer/tilt API, so this only answers the
    // channel (to avoid MissingPluginException) instead of returning a real angle.
    let channel = FlutterMethodChannel(
      name: "jjibudung/posture_service",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }

      switch call.method {
      case "ping":
        result("pong")

      case "start":
        self.sessionStartTime = Date()
        self.isSessionRunning = true
        result(true)

      case "stop":
        self.isSessionRunning = false
        result(true)

      case "getCurrentAngle":
        result(0.0)

      case "getSessionData":
        result(self.sessionData())

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let streamChannel = FlutterEventChannel(
      name: "jjibudung/posture_stream",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    streamChannel.setStreamHandler(postureStreamHandler)

    super.awakeFromNib()
  }
}
