import Foundation
import YiTongBridge

struct YiTongRenderRequestPlanner {
  struct Limits: Equatable, Sendable {
    var maxTotalBytes: Int
    var maxFileBytes: Int
    var maxFiles: Int

    static let `default` = Limits(
      maxTotalBytes: 10 * 1024 * 1024,
      maxFileBytes: 2 * 1024 * 1024,
      maxFiles: 200
    )
  }

  struct Failure: Equatable, Sendable, Error {
    var code: String
    var message: String
  }

  enum Result: Equatable, Sendable {
    case success(YiTongRenderRequest, diagnostic: String?)
    case failure(Failure)
  }

  static func plan(
    _ request: YiTongRenderRequest,
    limits: Limits = .default
  ) -> Result {
    guard let files = request.document.files, !files.isEmpty else {
      return .success(request, diagnostic: nil)
    }

    if let violation = firstViolation(in: files, limits: limits) {
      guard request.document.patch != nil else {
        return .failure(
          Failure(
            code: "document_too_large",
            message: "File-based diff exceeds supported limits and no patch fallback is available: \(violation)"
          )
        )
      }

      return .success(
        YiTongRenderRequest(
          document: YiTongBridgeDocumentPayload(
            identifier: request.document.identifier,
            title: request.document.title,
            patch: request.document.patch,
            files: nil
          ),
          configuration: request.configuration
        ),
        diagnostic: "Falling back to patch-based rendering: \(violation)"
      )
    }

    return .success(request, diagnostic: nil)
  }

  private static func firstViolation(
    in files: [YiTongBridgeFilePayload],
    limits: Limits
  ) -> String? {
    if files.count > limits.maxFiles {
      return "file count \(files.count) exceeds maxFiles \(limits.maxFiles)"
    }

    var totalBytes = 0

    for file in files {
      let fileBytes = file.oldContents.lengthOfBytes(using: .utf8)
        + file.newContents.lengthOfBytes(using: .utf8)

      if fileBytes > limits.maxFileBytes {
        let path = file.newPath ?? file.oldPath ?? "<unknown>"
        return "file \(path) size \(fileBytes) exceeds maxFileBytes \(limits.maxFileBytes)"
      }

      totalBytes += fileBytes
      if totalBytes > limits.maxTotalBytes {
        return "total size \(totalBytes) exceeds maxTotalBytes \(limits.maxTotalBytes)"
      }
    }

    return nil
  }
}
