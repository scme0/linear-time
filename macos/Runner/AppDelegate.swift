import Cocoa
import FlutterMacOS
import ServiceManagement
import Carbon

@main
class AppDelegate: FlutterAppDelegate {
  private var channel: FlutterMethodChannel?
  private var globalMonitor: Any?
  private var registeredKeyCode: UInt16 = 0
  private var registeredModifiers: NSEvent.ModifierFlags = []

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    channel = FlutterMethodChannel(name: "com.lineartime/system", binaryMessenger: controller.engine.binaryMessenger)

    channel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "setLaunchAtLogin":
        self?.handleSetLaunchAtLogin(call: call, result: result)

      case "setGlobalHotkey":
        self?.handleSetGlobalHotkey(call: call, result: result)

      case "clearGlobalHotkey":
        self?.clearGlobalHotkey()
        result(nil)

      case "bringToFront":
        NSApp.activate(ignoringOtherApps: true)
        self?.mainFlutterWindow?.makeKeyAndOrderFront(nil)
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Launch at Login

  private func handleSetLaunchAtLogin(call: FlutterMethodCall, result: @escaping FlutterResult) {
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
      result(nil)
    }
  }

  // MARK: - Global Hotkey

  private func handleSetGlobalHotkey(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let keyCode = args["keyCode"] as? Int,
          let modifiers = args["modifiers"] as? Int else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing keyCode/modifiers", details: nil))
      return
    }

    clearGlobalHotkey()

    registeredKeyCode = UInt16(keyCode)
    registeredModifiers = NSEvent.ModifierFlags(rawValue: UInt(modifiers))

    globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard let self = self else { return }

      let matchesKey = event.keyCode == self.registeredKeyCode
      // Check modifiers (mask to only care about cmd/ctrl/shift/option)
      let relevantMask: NSEvent.ModifierFlags = [.command, .control, .shift, .option]
      let eventMods = event.modifierFlags.intersection(relevantMask)
      let targetMods = self.registeredModifiers.intersection(relevantMask)
      let matchesMods = eventMods == targetMods

      if matchesKey && matchesMods {
        DispatchQueue.main.async {
          self.channel?.invokeMethod("onGlobalHotkey", arguments: nil)
        }
      }
    }

    result(nil)
  }

  private func clearGlobalHotkey() {
    if let monitor = globalMonitor {
      NSEvent.removeMonitor(monitor)
      globalMonitor = nil
    }
  }
}
