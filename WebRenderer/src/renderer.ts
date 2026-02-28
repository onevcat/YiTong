import { FileDiff, parsePatchFiles } from "@pierre/diffs";
import { postRenderStateChanged } from "./bridge";
import type { Envelope, IncomingMessageType, InitializePayload, RenderConfigurationPayload, RenderDocumentPayload } from "./protocol";
import { toDiffOptions } from "./theme";

interface RendererState {
  initializePayload?: InitializePayload;
  documentIdentifier?: string;
  configuration?: RenderConfigurationPayload;
}

const state: RendererState = {};
const instances: FileDiff[] = [];

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

function renderDocument(payload: RenderDocumentPayload) {
  const root = getAppRoot();
  const parsedPatches = parsePatchFiles(payload.document.patch);
  const files = parsedPatches.flatMap((patch) => patch.files);
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

  const options = toDiffOptions(payload.configuration);

  for (const fileDiff of files) {
    const section = document.createElement("section");
    section.className = "diff-file";
    root.appendChild(section);

    const instance = new FileDiff(options);
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
    case "updateConfiguration":
      if (state.documentIdentifier == null) {
        return;
      }
      return;
    case "teardown":
      clearInstances();
      getAppRoot().innerHTML = "";
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
