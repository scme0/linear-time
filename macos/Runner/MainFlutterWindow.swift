import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    self.minSize = NSSize(width: 680, height: 500)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  override func close() {
    // Hide instead of close so the app stays alive in the menu bar tray
    self.orderOut(nil)
  }
}
