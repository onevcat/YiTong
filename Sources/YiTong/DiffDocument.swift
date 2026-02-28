import Foundation

public struct DiffDocument: Sendable, Equatable {
  public var patch: String
  public var title: String?

  public init(patch: String, title: String? = nil) {
    self.patch = patch
    self.title = title
  }
}
