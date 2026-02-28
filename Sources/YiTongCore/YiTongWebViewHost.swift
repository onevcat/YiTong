import Foundation
import WebKit
import YiTongWebAssets

public final class YiTongWebViewHost: NSObject {
  public let webView: WKWebView

  public override init() {
    let configuration = WKWebViewConfiguration()
    configuration.defaultWebpagePreferences.allowsContentJavaScript = true
    self.webView = WKWebView(frame: .zero, configuration: configuration)
    super.init()
  }

  public func loadPlaceholderPage() {
    guard
      let fileURL = YiTongWebAssets.resourceURL(for: "index", withExtension: "html")
    else {
      return
    }

    webView.loadFileURL(fileURL, allowingReadAccessTo: YiTongWebAssets.resourcesDirectory)
  }
}
