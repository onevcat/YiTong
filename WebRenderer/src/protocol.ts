export const PROTOCOL_VERSION = 1;
export const RENDERER_VERSION = "0.1.0-placeholder";

export type OutgoingMessageType = "ready" | "renderStateChanged";
export type IncomingMessageType = "initialize" | "renderDocument" | "updateConfiguration" | "teardown";

export type ResolvedAppearance = "light" | "dark";
export type DiffStyle = "split" | "unified";
export type InlineChangeStyle = "wordAlt" | "word" | "char" | "none";
export type RenderState = "loading" | "rendered" | "failed";

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
  showsLineNumbers: boolean;
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
    patch: string;
  };
  configuration: RenderConfigurationPayload;
}

export interface ReadyPayload {
  rendererVersion: string;
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
