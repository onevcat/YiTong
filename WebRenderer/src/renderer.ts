import { FileDiff, parsePatchFiles } from "@pierre/diffs";
import { postLineActivated, postRenderStateChanged, postSelectionChanged } from "./bridge";
import type {
  Envelope,
  IncomingMessageType,
  InitializePayload,
  LineActivatedPayload,
  LineKind,
  LineSide,
  RenderConfigurationPayload,
  RenderDocumentPayload,
  SelectionChangedPayload,
  SelectionPayload,
} from "./protocol";
import { toDiffOptions } from "./theme";

interface RendererState {
  initializePayload?: InitializePayload;
  document?: RenderDocumentPayload["document"];
  documentIdentifier?: string;
  configuration?: RenderConfigurationPayload;
}

const state: RendererState = {};
const instances: FileDiff[] = [];

interface RenderedFileContext {
  fileIndex: number;
  oldPath?: string;
  newPath?: string;
}

function getAppRoot(): HTMLDivElement {
  const root = document.querySelector<HTMLDivElement>("#app");
  if (root == null) {
    throw new Error("Missing #app root element");
  }

  return root;
}

function clearInstances() {
  for (const instance of instances) {
    instance.cleanUp();
  }
  instances.length = 0;
}

function mapLineSide(side: "additions" | "deletions"): LineSide {
  switch (side) {
    case "deletions":
      return "old";
    case "additions":
      return "new";
  }
}

function mapLineKind(lineType: string): LineKind {
  switch (lineType) {
    case "change-addition":
      return "addition";
    case "change-deletion":
      return "deletion";
    case "context":
      return "context";
    case "context-expanded":
      return "expanded";
    default:
      return "metadata";
  }
}

function buildLineActivatedPayload(
  context: RenderedFileContext,
  props: {
    annotationSide: "additions" | "deletions";
    lineNumber: number;
    lineType: string;
  },
): LineActivatedPayload {
  return {
    fileIndex: context.fileIndex,
    oldPath: context.oldPath,
    newPath: context.newPath,
    side: mapLineSide(props.annotationSide),
    number: props.lineNumber,
    kind: mapLineKind(props.lineType),
  };
}

function buildSelectionChangedPayload(
  context: RenderedFileContext,
  range: {
    start: number;
    side?: "additions" | "deletions";
    end: number;
    endSide?: "additions" | "deletions";
  } | null,
): SelectionChangedPayload {
  if (range == null) {
    return { selection: null };
  }

  const selection: SelectionPayload = {
    fileIndex: context.fileIndex,
    start: {
      side: range.side == null ? "unified" : mapLineSide(range.side),
      number: range.start,
    },
    end: {
      side: range.endSide == null ? (range.side == null ? "unified" : mapLineSide(range.side)) : mapLineSide(range.endSide),
      number: range.end,
    },
  };

  return { selection };
}

function renderDocument(payload: RenderDocumentPayload) {
  const root = getAppRoot();
  const parsedPatches = parsePatchFiles(payload.document.patch);
  const files = parsedPatches.flatMap((patch) => patch.files);
  state.document = payload.document;
  state.documentIdentifier = payload.document.identifier;
  state.configuration = payload.configuration;

  postRenderStateChanged({
    state: "loading",
    documentIdentifier: payload.document.identifier,
  });

  clearInstances();
  root.innerHTML = "";

  if (files.length === 0) {
    throw new Error("No file diffs were parsed from the provided patch");
  }

  for (const [fileIndex, fileDiff] of files.entries()) {
    const section = document.createElement("section");
    section.className = "diff-file";
    root.appendChild(section);

    const context: RenderedFileContext = {
      fileIndex,
      oldPath: fileDiff.prevName,
      newPath: fileDiff.name,
    };
    const instance = new FileDiff({
      ...toDiffOptions(payload.configuration),
      onLineClick(props) {
        postLineActivated(buildLineActivatedPayload(context, props));
      },
      onLineSelected(range) {
        postSelectionChanged(buildSelectionChangedPayload(context, range));
      },
    });
    instance.render({
      fileDiff,
      containerWrapper: section,
    });
    instances.push(instance);
  }

  postRenderStateChanged({
    state: "rendered",
    documentIdentifier: payload.document.identifier,
    summary: {
      fileCount: files.length,
    },
  });
}

export async function handleIncomingMessage(envelope: Envelope<IncomingMessageType, unknown>) {
  switch (envelope.type) {
    case "initialize":
      state.initializePayload = envelope.payload as InitializePayload;
      return;
    case "renderDocument":
      renderDocument(envelope.payload as RenderDocumentPayload);
      return;
    case "updateConfiguration": {
      if (state.document == null) {
        return;
      }

      renderDocument({
        document: state.document,
        configuration: envelope.payload as RenderConfigurationPayload,
      });
      return;
    }
    case "teardown":
      clearInstances();
      getAppRoot().innerHTML = "";
      state.document = undefined;
      state.documentIdentifier = undefined;
      state.configuration = undefined;
      return;
  }
}

export function handleMessageError(error: unknown) {
  const normalized = error instanceof Error ? error : new Error(String(error));
  postRenderStateChanged({
    state: "failed",
    documentIdentifier: state.documentIdentifier,
    error: {
      code: "render_failed",
      message: normalized.message,
    },
  });
}
