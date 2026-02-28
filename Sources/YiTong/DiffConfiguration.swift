import Foundation

/// Public configuration for `DiffView`.
///
/// YiTong keeps these names Swift-native on purpose and documents the upstream
/// `diffs` vanilla option mapping here instead of mirroring web renderer names 1:1.
public struct DiffConfiguration: Sendable, Equatable {
  /// Maps to upstream `themeType` after resolving `.automatic`.
  public var appearance: DiffAppearance
  /// Maps to upstream `diffStyle`.
  public var style: DiffStyle
  /// Maps to upstream `diffIndicators`.
  public var indicators: DiffIndicators
  /// Inverse of upstream `disableLineNumbers`.
  public var showsLineNumbers: Bool
  /// Inverse of upstream `disableBackground`.
  public var showsChangeBackgrounds: Bool
  /// Maps to upstream `overflow` as `wrap` or scrolling behavior.
  public var wrapsLines: Bool
  /// Inverse of upstream `disableFileHeader`.
  public var showsFileHeaders: Bool
  /// Maps to upstream `lineDiffType`.
  public var inlineChangeStyle: DiffInlineChangeStyle
  /// Maps to upstream `enableLineSelection`.
  public var allowsSelection: Bool

  public init(
    appearance: DiffAppearance = .automatic,
    style: DiffStyle = .split,
    indicators: DiffIndicators = .bars,
    showsLineNumbers: Bool = true,
    showsChangeBackgrounds: Bool = true,
    wrapsLines: Bool = false,
    showsFileHeaders: Bool = true,
    inlineChangeStyle: DiffInlineChangeStyle = .wordAlt,
    allowsSelection: Bool = true
  ) {
    self.appearance = appearance
    self.style = style
    self.indicators = indicators
    self.showsLineNumbers = showsLineNumbers
    self.showsChangeBackgrounds = showsChangeBackgrounds
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

/// Maps to upstream `diffStyle`.
public enum DiffStyle: String, Sendable, Equatable {
  case split
  case unified
}

/// Maps to upstream `diffIndicators`.
public enum DiffIndicators: String, Sendable, Equatable {
  case bars
  case classic
  case none
}

/// Maps to upstream `lineDiffType`.
public enum DiffInlineChangeStyle: String, Sendable, Equatable {
  case wordAlt
  case word
  case char
  case none
}
