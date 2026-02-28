import Foundation

public struct DiffConfiguration: Sendable, Equatable {
  public var appearance: DiffAppearance
  public var style: DiffStyle
  public var showsLineNumbers: Bool
  public var wrapsLines: Bool
  public var showsFileHeaders: Bool
  public var inlineChangeStyle: DiffInlineChangeStyle
  public var allowsSelection: Bool

  public init(
    appearance: DiffAppearance = .automatic,
    style: DiffStyle = .split,
    showsLineNumbers: Bool = true,
    wrapsLines: Bool = false,
    showsFileHeaders: Bool = true,
    inlineChangeStyle: DiffInlineChangeStyle = .wordAlt,
    allowsSelection: Bool = true
  ) {
    self.appearance = appearance
    self.style = style
    self.showsLineNumbers = showsLineNumbers
    self.wrapsLines = wrapsLines
    self.showsFileHeaders = showsFileHeaders
    self.inlineChangeStyle = inlineChangeStyle
    self.allowsSelection = allowsSelection
  }

  public static let `default` = DiffConfiguration()
}

public enum DiffAppearance: String, Sendable, Equatable {
  case automatic
  case light
  case dark
}

public enum DiffStyle: String, Sendable, Equatable {
  case split
  case unified
}

public enum DiffInlineChangeStyle: String, Sendable, Equatable {
  case wordAlt
  case word
  case char
  case none
}
