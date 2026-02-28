import Foundation

public enum YiTongRendererState: String, Sendable, Equatable {
  case idle
  case loadingPage
  case waitingForReady
  case renderingDocument
  case rendered
  case failed
  case terminated
}
