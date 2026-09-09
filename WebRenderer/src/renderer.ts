import { FileDiff } from "@pierre/diffs";
import { createAnnotationContentElement, resolveActivatedAction } from "./annotationContent";
import {
  annotationsForFile,
  buildAnnotationActivatedPayload,
  groupAnnotationsByFile,
  type LineAnnotationForFile,
} from "./annotationModel";
import { postAnnotationActivated, postLineActivated, postRenderStateChanged, postSelectionChanged } from "./bridge";
import type {
  AnnotationPayload,
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
  UpdateAnnotationsPayload,
} from "./protocol";
import { buildRenderedFiles, type RenderedDocumentFile } from "./renderDocumentModel";
import { toDiffOptions } from "./theme";

interface RendererState {
  initializePayload?: InitializePayload;
  document?: RenderDocumentPayload["document"];
  documentIdentifier?: string;
  configuration?: RenderConfigurationPayload;
  annotations: AnnotationPayload[];
  renderedFiles: RenderedDocumentFile[];
}

const state: RendererState = { annotations: [], renderedFiles: [] };
const instances: FileDiff<AnnotationPayload>[] = [];
let annotationClickListenerInstalled = false;

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

function applyAppearance(appearance: "light" | "dark") {
  document.documentElement.dataset.appearance = appearance;
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

function renderAnnotation(annotation: LineAnnotationForFile): HTMLElement {
  return createAnnotationContentElement(annotation.metadata);
}

function installAnnotationClickListener(root: HTMLElement) {
  if (annotationClickListenerInstalled) {
    return;
  }
  annotationClickListenerInstalled = true;

  root.addEventListener("click", (event) => {
    const activated = resolveActivatedAction(event.target);
    if (activated == null) {
      return;
    }

    const annotation = state.annotations.find((candidate) => candidate.id === activated.annotationID);
    if (annotation == null) {
      return;
    }

    event.preventDefault();
    postAnnotationActivated(buildAnnotationActivatedPayload(annotation, activated.action));
  });
}

function updateAnnotations(payload: UpdateAnnotationsPayload) {
  state.annotations = payload.annotations;
  const grouped = groupAnnotationsByFile(state.annotations, state.renderedFiles.length);

  // Re-rendering without `forceRender` reuses the highlight cache, so only the
  // annotation slots and their content are rebuilt.
  for (const [fileIndex, instance] of instances.entries()) {
    instance.render({
      fileDiff: state.renderedFiles[fileIndex].fileDiff,
      lineAnnotations: annotationsForFile(grouped, fileIndex),
    });
  }
}

function renderDocument(payload: RenderDocumentPayload) {
  const root = getAppRoot();
  const renderedFiles = buildRenderedFiles(payload.document);
  state.document = payload.document;
  state.documentIdentifier = payload.document.identifier;
  state.configuration = payload.configuration;
  state.annotations = payload.annotations ?? [];
  state.renderedFiles = renderedFiles;
  const groupedAnnotations = groupAnnotationsByFile(state.annotations, renderedFiles.length);
  applyAppearance(payload.configuration.resolvedAppearance);
  installAnnotationClickListener(root);

  postRenderStateChanged({
    state: "loading",
    documentIdentifier: payload.document.identifier,
  });

  clearInstances();
  root.innerHTML = "";

  for (const [fileIndex, renderedFile] of renderedFiles.entries()) {
    const section = document.createElement("section");
    section.className = "diff-file";
    root.appendChild(section);

    const context: RenderedFileContext = {
      fileIndex,
      oldPath: renderedFile.oldPath,
      newPath: renderedFile.newPath,
    };
    const instance = new FileDiff<AnnotationPayload>({
      ...toDiffOptions(payload.configuration),
      onLineClick(props) {
        postLineActivated(buildLineActivatedPayload(context, props));
      },
      onLineSelected(range) {
        postSelectionChanged(buildSelectionChangedPayload(context, range));
      },
      renderAnnotation,
    });
    instance.render({
      fileDiff: renderedFile.fileDiff,
      containerWrapper: section,
      lineAnnotations: annotationsForFile(groupedAnnotations, fileIndex),
    });
    instances.push(instance);
  }

  postRenderStateChanged({
    state: "rendered",
    documentIdentifier: payload.document.identifier,
    summary: {
      fileCount: renderedFiles.length,
    },
  });
}

export async function handleIncomingMessage(envelope: Envelope<IncomingMessageType, unknown>) {
  switch (envelope.type) {
    case "initialize":
      state.initializePayload = envelope.payload as InitializePayload;
      applyAppearance(state.initializePayload.resolvedAppearance);
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
        annotations: state.annotations,
      });
      return;
    }
    case "updateAnnotations":
      if (state.document == null) {
        return;
      }

      updateAnnotations(envelope.payload as UpdateAnnotationsPayload);
      return;
    case "teardown":
      clearInstances();
      getAppRoot().innerHTML = "";
      state.document = undefined;
      state.documentIdentifier = undefined;
      state.configuration = undefined;
      state.annotations = [];
      state.renderedFiles = [];
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
