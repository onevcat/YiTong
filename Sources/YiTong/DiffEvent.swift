import Foundation

public enum DiffEvent: Sendable, Equatable {
  case didFinishInitialLoad
  case didRender(DiffRenderSummary)
  case didClickLine(DiffLineReference)
  case didChangeSelection(DiffSelection?)
  case didFail(DiffError)
}

public struct DiffRenderSummary: Sendable, Equatable {
  public var fileCount: Int

  public init(fileCount: Int) {
    self.fileCount = fileCount
  }
}

public struct DiffLineReference: Sendable, Equatable {
  public var fileIndex: Int
  public var oldPath: String?
  public var newPath: String?
  public var side: DiffLineSide
  public var number: Int
  public var kind: DiffLineKind

  public init(
    fileIndex: Int,
    oldPath: String? = nil,
    newPath: String? = nil,
    side: DiffLineSide,
    number: Int,
    kind: DiffLineKind
  ) {
    self.fileIndex = fileIndex
    self.oldPath = oldPath
    self.newPath = newPath
    self.side = side
    self.number = number
    self.kind = kind
  }
}

public enum DiffLineSide: String, Sendable, Equatable {
  case old
  case new
  case unified
}

public enum DiffLineKind: String, Sendable, Equatable {
  case context
  case addition
  case deletion
  case metadata
  case expanded
}

public struct DiffSelection: Sendable, Equatable {
  public var fileIndex: Int
  public var start: DiffSelectionEndpoint
  public var end: DiffSelectionEndpoint

  public init(fileIndex: Int, start: DiffSelectionEndpoint, end: DiffSelectionEndpoint) {
    self.fileIndex = fileIndex
    self.start = start
    self.end = end
  }
}

public struct DiffSelectionEndpoint: Sendable, Equatable {
  public var side: DiffLineSide
  public var number: Int

  public init(side: DiffLineSide, number: Int) {
    self.side = side
    self.number = number
  }
}

public struct DiffError: Error, Sendable, Equatable {
  public var code: String
  public var message: String

  public init(code: String, message: String) {
    self.code = code
    self.message = message
  }
}
