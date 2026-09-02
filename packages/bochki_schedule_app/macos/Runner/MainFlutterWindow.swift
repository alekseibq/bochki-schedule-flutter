import Cocoa
import FlutterMacOS
import desktop_multi_window

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      NSLog("[macos-minimal] registering generated plugins for child controller")
      RegisterGeneratedPlugins(registry: controller)
      NSLog("[macos-minimal] generated plugins registered for child controller")
    }

    super.awakeFromNib()
  }
}
