import Cocoa
import FlutterMacOS
import ServiceManagement
import Carbon
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate {
  private var channel: FlutterMethodChannel?
  private var globalMonitor: Any?
  private var localMonitor: Any?
  private var registeredKeyCode: UInt16 = 0
  private var registeredModifiers: NSEvent.ModifierFlags = []

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationWillFinishLaunching(_ notification: Notification) {
    // Single instance check — if already running, focus existing and exit
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
    if running.count > 1 {
      // Another instance exists — activate it and terminate this one
      for app in running where app != NSRunningApplication.current {
        app.activate()
      }
      NSApp.terminate(nil)
      return
    }
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
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        self?.mainFlutterWindow?.makeKeyAndOrderFront(nil)
        result(nil)

      case "showOverlay":
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let message = args["message"] as? String,
              let actions = args["actions"] as? [String] else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing title/message/actions", details: nil))
          return
        }
        OverlayWindow.shared.show(title: title, message: message, actions: actions) { action in
          DispatchQueue.main.async {
            self?.channel?.invokeMethod("onOverlayResponse", arguments: action)
          }
        }
        result(nil)

      case "dismissOverlay":
        OverlayWindow.shared.dismiss()
        result(nil)

      case "sendNotification":
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let body = args["body"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing title/body", details: nil))
          return
        }
        self?.sendNotification(title: title, body: body, id: args["id"] as? String ?? "default")
        result(nil)

      case "requestNotificationPermission":
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
          DispatchQueue.main.async { result(granted) }
        }

      case "getIdleSeconds":
        let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
        let idleKb = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        result(Int(min(idle, idleKb)))

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Notifications

  private func sendNotification(title: String, body: String, id: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)
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

    // Request accessibility permission if needed
    let trusted = AXIsProcessTrustedWithOptions(
      [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
    )

    if !trusted {
      NSLog("Linear Time: Accessibility permission not yet granted. Hotkey may not work until granted.")
    }

    // Monitor when app is NOT focused
    globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
      self?.handleHotkeyEvent(event)
    }

    // Monitor when app IS focused
    localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      if self?.checkHotkeyMatch(event) == true {
        self?.fireHotkey()
        return nil  // consume the event
      }
      return event
    }

    result(nil)
  }

  private func handleHotkeyEvent(_ event: NSEvent) {
    if checkHotkeyMatch(event) {
      fireHotkey()
    }
  }

  private func checkHotkeyMatch(_ event: NSEvent) -> Bool {
    let matchesKey = event.keyCode == registeredKeyCode
    let relevantMask: NSEvent.ModifierFlags = [.command, .control, .shift, .option]
    let eventMods = event.modifierFlags.intersection(relevantMask)
    let targetMods = registeredModifiers.intersection(relevantMask)
    return matchesKey && eventMods == targetMods
  }

  private func fireHotkey() {
    DispatchQueue.main.async {
      self.channel?.invokeMethod("onGlobalHotkey", arguments: nil)
    }
  }

  private func clearGlobalHotkey() {
    if let monitor = globalMonitor {
      NSEvent.removeMonitor(monitor)
      globalMonitor = nil
    }
    if let monitor = localMonitor {
      NSEvent.removeMonitor(monitor)
      localMonitor = nil
    }
  }
}
