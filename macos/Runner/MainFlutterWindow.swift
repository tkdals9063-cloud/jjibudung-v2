import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
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

    super.awakeFromNib()
  }
}
