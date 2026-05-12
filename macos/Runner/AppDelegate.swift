import Cocoa
import FlutterMacOS
import ServiceManagement

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.lineartime/system", binaryMessenger: controller.engine.binaryMessenger)

    channel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "setLaunchAtLogin":
        guard let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing 'enabled' argument", details: nil))
          return
        }

        if #available(macOS 13.0, *) {
          do {
            if enabled {
              try SMAppService.mainApp.register()
            } else {
              try SMAppService.mainApp.unregister()
            }
            result(nil)
          } catch {
            result(FlutterError(code: "SM_ERROR", message: error.localizedDescription, details: nil))
          }
        } else {
          // Fallback for older macOS — just save the preference, no-op for actual registration
          result(nil)
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
