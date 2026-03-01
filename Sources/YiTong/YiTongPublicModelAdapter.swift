import Foundation
import YiTongBridge
import YiTongCore

enum YiTongPublicModelAdapter {
  static func makeRenderRequest(
    documentIdentifier: String,
    document: DiffDocument,
    configuration: DiffConfiguration,
    resolvedAppearance: YiTongBridgeResolvedAppearance
  ) -> YiTongRenderRequest {
    YiTongRenderRequest(
      document: YiTongBridgeDocumentPayload(
        identifier: documentIdentifier,
        title: document.title,
        patch: document.patch,
        files: document.files?.map {
          YiTongBridgeFilePayload(
            oldPath: $0.oldPath,
            newPath: $0.newPath,
            oldContents: $0.oldContents,
            newContents: $0.newContents
          )
        }
      ),
      configuration: makeBridgeConfiguration(
        from: configuration,
        resolvedAppearance: resolvedAppearance
      )
    )
  }

  static func makeBridgeConfiguration(
    from configuration: DiffConfiguration,
    resolvedAppearance: YiTongBridgeResolvedAppearance
  ) -> YiTongBridgeConfigurationPayload {
    YiTongBridgeConfigurationPayload(
      diffStyle: configuration.style == .split ? .split : .unified,
      diffIndicators: {
        switch configuration.indicators {
        case .bars:
          return .bars
        case .classic:
          return .classic
        case .none:
          return .none
        }
      }(),
      showsLineNumbers: configuration.showsLineNumbers,
      showsChangeBackgrounds: configuration.showsChangeBackgrounds,
      wrapsLines: configuration.wrapsLines,
      showsFileHeaders: configuration.showsFileHeaders,
      inlineChangeStyle: {
        switch configuration.inlineChangeStyle {
        case .wordAlt:
          return .wordAlt
        case .word:
          return .word
        case .char:
          return .char
        case .none:
          return .none
        }
      }(),
      allowsSelection: configuration.allowsSelection,
      resolvedAppearance: resolvedAppearance
    )
  }

  static func makeDiffEvent(from event: YiTongHostEvent) -> DiffEvent {
    switch event {
    case .didFinishInitialLoad:
      return .didFinishInitialLoad
    case .didRender(let fileCount):
      return .didRender(DiffRenderSummary(fileCount: fileCount))
    case .didActivateLine(let payload):
      return .didClickLine(
        DiffLineReference(
          fileIndex: payload.fileIndex,
          oldPath: payload.oldPath,
          newPath: payload.newPath,
          side: {
            switch payload.side {
            case .old:
              return .old
            case .new:
              return .new
            case .unified:
              return .unified
            }
          }(),
          number: payload.number,
          kind: {
            switch payload.kind {
            case .context:
              return .context
            case .addition:
              return .addition
            case .deletion:
              return .deletion
            case .metadata:
              return .metadata
            case .expanded:
              return .expanded
            }
          }()
        )
      )
    case .didChangeSelection(let selection):
      return .didChangeSelection(
        selection.map { selection in
          DiffSelection(
            fileIndex: selection.fileIndex,
            start: DiffSelectionEndpoint(
              side: {
                switch selection.start.side {
                case .old:
                  return .old
                case .new:
                  return .new
                case .unified:
                  return .unified
                }
              }(),
              number: selection.start.number
            ),
            end: DiffSelectionEndpoint(
              side: {
                switch selection.end.side {
                case .old:
                  return .old
                case .new:
                  return .new
                case .unified:
                  return .unified
                }
              }(),
              number: selection.end.number
            )
          )
        }
      )
    case .didFail(let code, let message):
      return .didFail(DiffError(code: code, message: message))
    }
  }
}
