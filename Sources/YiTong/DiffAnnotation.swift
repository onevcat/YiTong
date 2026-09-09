import Foundation

/// Host-provided content rendered beneath a single diff line.
///
/// YiTong is deliberately agnostic about what an annotation means: a review
/// thread, a comment composer, a lint warning. The host renders the content
/// and reacts to `DiffEvent.didActivateAnnotation` for anything interactive.
///
/// Multi-line annotations anchor to one line (typically the end of the range);
/// range information, if any, is drawn by the host into the content.
public struct DiffAnnotation: Sendable, Equatable, Identifiable {
  /// Stable identifier echoed back in `DiffAnnotationAction`.
  public var id: String
  /// Index of the file within the rendered document.
  public var fileIndex: Int
  /// Which side of the diff the line number refers to.
  public var side: DiffAnnotationSide
  public var lineNumber: Int
  /// Free-form host category (for example `"thread"` or `"composer"`), echoed back in actions.
  public var kind: String?
  public var content: DiffAnnotationContent

  public init(
    id: String,
    fileIndex: Int,
    side: DiffAnnotationSide,
    lineNumber: Int,
    kind: String? = nil,
    content: DiffAnnotationContent
  ) {
    self.id = id
    self.fileIndex = fileIndex
    self.side = side
    self.lineNumber = lineNumber
    self.kind = kind
    self.content = content
  }
}

public enum DiffAnnotationSide: String, Sendable, Equatable {
  case old
  case new
}

public enum DiffAnnotationContent: Sendable, Equatable {
  /// Pre-rendered HTML inserted verbatim beneath the line.
  ///
  /// The host owns content safety. The renderer strips script execution
  /// vectors (`<script>`, `on*` handlers, `javascript:` URLs) and nothing else.
  /// Elements carrying a `data-action` attribute report clicks through
  /// `DiffEvent.didActivateAnnotation`.
  case html(String)
  /// Plain text inserted as-is.
  case text(String)
}

/// A click on an element with `data-action` inside an annotation.
public struct DiffAnnotationAction: Sendable, Equatable {
  public var annotationID: String
  /// Value of the `data-action` attribute the host placed on the clicked element.
  public var action: String
  public var kind: String?
  public var fileIndex: Int
  public var side: DiffAnnotationSide
  public var lineNumber: Int

  public init(
    annotationID: String,
    action: String,
    kind: String? = nil,
    fileIndex: Int,
    side: DiffAnnotationSide,
    lineNumber: Int
  ) {
    self.annotationID = annotationID
    self.action = action
    self.kind = kind
    self.fileIndex = fileIndex
    self.side = side
    self.lineNumber = lineNumber
  }
}
