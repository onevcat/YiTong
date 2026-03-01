import { parseDiffFromFile, parsePatchFiles, type FileContents, type FileDiffMetadata } from "@pierre/diffs";
import type { RenderDocumentPayload } from "./protocol";

export type RenderMode = "files" | "patch";

export interface RenderedDocumentFile {
  fileDiff: FileDiffMetadata;
  oldPath?: string;
  newPath?: string;
}

type RenderDocument = RenderDocumentPayload["document"];
type RenderDocumentFilePayload = NonNullable<RenderDocument["files"]>[number];

export function selectRenderMode(document: RenderDocument): RenderMode {
  if (document.files != null && document.files.length > 0) {
    return "files";
  }

  if (document.patch != null && document.patch.length > 0) {
    return "patch";
  }

  throw new Error("No renderable diff input was provided");
}

export function buildRenderedFiles(document: RenderDocument): RenderedDocumentFile[] {
  switch (selectRenderMode(document)) {
    case "files":
      return document.files!.map((file) => ({
        fileDiff: parseDiffFromFile(makeOldFile(file), makeNewFile(file)),
        oldPath: file.oldPath,
        newPath: file.newPath,
      }));
    case "patch": {
      const files = parsePatchFiles(document.patch!).flatMap((patch) =>
        patch.files.map((fileDiff) => ({
          fileDiff,
          oldPath: fileDiff.prevName,
          newPath: fileDiff.name,
        })),
      );

      if (files.length == 0) {
        throw new Error("No file diffs were parsed from the provided patch");
      }

      return files;
    }
  }
}

function makeOldFile(file: RenderDocumentFilePayload): FileContents {
  return {
    name: file.oldPath ?? file.newPath ?? "OldFile",
    contents: file.oldContents,
  };
}

function makeNewFile(file: RenderDocumentFilePayload): FileContents {
  return {
    name: file.newPath ?? file.oldPath ?? "NewFile",
    contents: file.newContents,
  };
}
