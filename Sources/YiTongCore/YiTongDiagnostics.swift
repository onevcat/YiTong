import Foundation

enum YiTongDiagnostics {
  private static let enabledValues: Set<String> = ["1", "true", "yes", "on"]
  private static let environmentKey = "YITONG_DEBUG"

  static func isEnabled(environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
    guard let rawValue = environment[environmentKey] else {
      return false
    }

    return enabledValues.contains(rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
  }
}
