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
      NSLog("[bochki-lifecycle] registering generated plugins for child controller")
      RegisterGeneratedPlugins(registry: controller)
      NSLog("[bochki-lifecycle] generated plugins registered for child controller")
    }

    super.awakeFromNib()
  }
}
