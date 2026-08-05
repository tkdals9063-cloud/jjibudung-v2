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

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "ping":
        result("pong")

      case "start", "stop":
        result(true)

      case "getCurrentAngle":
        result(0.0)

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
