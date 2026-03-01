import Foundation

public struct DiffFile: Sendable, Equatable {
  public var oldPath: String?
  public var newPath: String?
  public var oldContents: String
  public var newContents: String

  public init(
    oldPath: String? = nil,
    newPath: String? = nil,
    oldContents: String,
    newContents: String
  ) {
    self.oldPath = oldPath
    self.newPath = newPath
    self.oldContents = oldContents
    self.newContents = newContents
  }
}

public struct DiffDocument: Sendable, Equatable {
  public private(set) var patch: String?
  public private(set) var files: [DiffFile]?
  public var title: String?

  public init(patch: String, title: String? = nil) {
    self.patch = patch
    self.files = nil
    self.title = title
  }

  public init(files: [DiffFile], title: String? = nil, fallbackPatch: String? = nil) {
    self.patch = fallbackPatch
    self.files = files
    self.title = title
  }
}
