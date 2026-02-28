import Foundation

public enum YiTongWebAssets {
  public static let bundle = Bundle.module

  public static var resourcesDirectory: URL {
    bundle.resourceURL ?? URL(fileURLWithPath: NSTemporaryDirectory())
  }

  public static func resourceURL(for name: String, withExtension extensionName: String) -> URL? {
    bundle.url(forResource: name, withExtension: extensionName)
  }

  public static func loadManifest() throws -> YiTongWebAssetsManifest {
    guard let url = resourceURL(for: "manifest", withExtension: "json") else {
      throw CocoaError(.fileNoSuchFile)
    }

    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(YiTongWebAssetsManifest.self, from: data)
  }
}

public struct YiTongWebAssetsManifest: Codable, Equatable, Sendable {
  public var rendererVersion: String
  public var protocolVersion: Int
  public var files: [String]

  public init(rendererVersion: String, protocolVersion: Int, files: [String]) {
    self.rendererVersion = rendererVersion
    self.protocolVersion = protocolVersion
    self.files = files
  }
}
