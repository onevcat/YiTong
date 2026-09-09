export const PROTOCOL_VERSION = 1;
export const RENDERER_VERSION = "0.1.0-placeholder";

export type OutgoingMessageType =
  | "ready"
  | "renderStateChanged"
  | "lineActivated"
  | "selectionChanged"
  | "annotationActivated";
export type IncomingMessageType =
  | "initialize"
  | "renderDocument"
  | "updateConfiguration"
  | "updateAnnotations"
  | "teardown";

export type ResolvedAppearance = "light" | "dark";
export type DiffStyle = "split" | "unified";
export type DiffIndicators = "bars" | "classic" | "none";
export type InlineChangeStyle = "wordAlt" | "word" | "char" | "none";
export type RenderState = "loading" | "rendered" | "failed";
export type LineSide = "old" | "new" | "unified";
export type LineKind = "context" | "addition" | "deletion" | "metadata" | "expanded";
export type AnnotationSide = "old" | "new";

export interface Envelope<TType extends string, TPayload> {
  protocolVersion: number;
  id: string;
  type: TType;
  payload: TPayload;
}

export interface InitializePayload {
  rendererVersion: string;
  platform: "ios" | "macos";
  resolvedAppearance: ResolvedAppearance;
  features: {
    selection: boolean;
    workerMode: boolean;
  };
}

export interface RenderConfigurationPayload {
  diffStyle: DiffStyle;
  diffIndicators: DiffIndicators;
  showsLineNumbers: boolean;
  showsChangeBackgrounds: boolean;
  wrapsLines: boolean;
  showsFileHeaders: boolean;
  inlineChangeStyle: InlineChangeStyle;
  allowsSelection: boolean;
  resolvedAppearance: ResolvedAppearance;
}

export interface RenderDocumentPayload {
  document: {
    identifier: string;
    title?: string;
    patch?: string;
    files?: Array<{
      oldPath?: string;
      newPath?: string;
      oldContents: string;
      newContents: string;
    }>;
  };
  configuration: RenderConfigurationPayload;
  annotations?: AnnotationPayload[];
}

/**
 * Host-provided content rendered beneath a diff line.
 *
 * The host owns the content: `html` is inserted as-is apart from script
 * stripping, `text` is inserted as plain text. Multi-line annotations are
 * anchored to a single line; the host draws range information into its content.
 */
export interface AnnotationPayload {
  id: string;
  fileIndex: number;
  side: AnnotationSide;
  lineNumber: number;
  kind?: string;
  html?: string;
  text?: string;
}

export interface UpdateAnnotationsPayload {
  annotations: AnnotationPayload[];
}

export interface ReadyPayload {
  rendererVersion: string;
}

export interface EmptyPayload {
}

export interface RenderStateChangedPayload {
  state: RenderState;
  documentIdentifier?: string;
  summary?: {
    fileCount: number;
  };
  error?: {
    code: string;
    message: string;
  };
}

export interface LineActivatedPayload {
  fileIndex: number;
  oldPath?: string;
  newPath?: string;
  side: LineSide;
  number: number;
  kind: LineKind;
}

export interface SelectionEndpointPayload {
  side: LineSide;
  number: number;
}

export interface SelectionPayload {
  fileIndex: number;
  start: SelectionEndpointPayload;
  end: SelectionEndpointPayload;
}

export interface SelectionChangedPayload {
  selection: SelectionPayload | null;
}

export interface AnnotationActivatedPayload {
  id: string;
  action: string;
  kind?: string;
  fileIndex: number;
  side: AnnotationSide;
  lineNumber: number;
}
