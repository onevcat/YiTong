import Foundation
import YiTong

enum SampleAnnotation {
  static let threadID = "sample-thread"
  static let replyAction = "reply"
  static let resolveAction = "resolve"

  struct Message: Equatable {
    var author: String
    var body: String
  }

  static let seedMessages: [Message] = [
    Message(author: "Amadeus", body: "Should reset() also notify observers, or is the caller expected to?"),
    Message(author: "Mark", body: "Caller side. Counter stays a plain value type."),
  ]

  /// Anchors to the `mutating func reset()` line introduced by the sample patch.
  static func thread(messages: [Message]) -> DiffAnnotation {
    DiffAnnotation(
      id: threadID,
      fileIndex: 0,
      side: .new,
      lineNumber: 6,
      kind: "thread",
      content: .html(threadHTML(messages: messages))
    )
  }

  private static func threadHTML(messages: [Message]) -> String {
    let items = messages.map { message in
      """
      <li style="margin: 0 0 6px 0;">
        <strong>\(escape(message.author))</strong>
        <span style="opacity: 0.7;">&middot; just now</span><br>
        \(escape(message.body))
      </li>
      """
    }.joined()

    return """
    <div style="display: flex; flex-direction: column; gap: 8px;">
      <ul style="list-style: none; margin: 0; padding: 0;">\(items)</ul>
      <div style="display: flex; gap: 8px;">
        <button data-action="\(replyAction)" type="button">Reply</button>
        <button data-action="\(resolveAction)" type="button">Resolve</button>
      </div>
    </div>
    """
  }

  private static func escape(_ text: String) -> String {
    text
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
  }
}
