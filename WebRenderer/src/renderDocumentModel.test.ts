import { describe, expect, it, vi, beforeEach } from "vitest";
import { buildRenderedFiles, selectRenderMode } from "./renderDocumentModel";
import type { RenderDocumentPayload } from "./protocol";

const { parsePatchFiles, parseDiffFromFile } = vi.hoisted(() => ({
  parsePatchFiles: vi.fn(),
  parseDiffFromFile: vi.fn(),
}));

vi.mock("@pierre/diffs", () => ({
  parsePatchFiles,
  parseDiffFromFile,
}));

describe("selectRenderMode", () => {
  it("prefers file mode when files are present", () => {
    const mode = selectRenderMode({
      identifier: "document-1",
      patch: "diff --git a/a.txt b/a.txt",
      files: [
        {
          oldPath: "a.txt",
          newPath: "a.txt",
          oldContents: "before\n",
          newContents: "after\n",
        },
      ],
    });

    expect(mode).toBe("files");
  });

  it("uses patch mode when only patch is present", () => {
    const mode = selectRenderMode({
      identifier: "document-1",
      patch: "diff --git a/a.txt b/a.txt",
    });

    expect(mode).toBe("patch");
  });
});

describe("buildRenderedFiles", () => {
  beforeEach(() => {
    parsePatchFiles.mockReset();
    parseDiffFromFile.mockReset();
  });

  it("calls parseDiffFromFile for each file in file mode", () => {
    parseDiffFromFile
      .mockReturnValueOnce({ name: "a.txt", prevName: "a.txt", hunks: [] })
      .mockReturnValueOnce({ name: "b.txt", prevName: "b.txt", hunks: [] });

    const payload: RenderDocumentPayload = {
      document: {
        identifier: "document-files",
        patch: "diff --git a/fallback.txt b/fallback.txt",
        files: [
          {
            oldPath: "a.txt",
            newPath: "a.txt",
            oldContents: "before a\n",
            newContents: "after a\n",
          },
          {
            oldPath: "b.txt",
            newPath: "b.txt",
            oldContents: "before b\n",
            newContents: "after b\n",
          },
        ],
      },
      configuration: {
        diffStyle: "split",
        diffIndicators: "bars",
        showsLineNumbers: true,
        showsChangeBackgrounds: true,
        wrapsLines: false,
        showsFileHeaders: true,
        inlineChangeStyle: "wordAlt",
        allowsSelection: true,
        resolvedAppearance: "dark",
      },
    };

    const renderedFiles = buildRenderedFiles(payload.document);

    expect(parseDiffFromFile).toHaveBeenCalledTimes(2);
    expect(parsePatchFiles).not.toHaveBeenCalled();
    expect(renderedFiles).toHaveLength(2);
    expect(renderedFiles[0]).toMatchObject({
      oldPath: "a.txt",
      newPath: "a.txt",
    });
    expect(renderedFiles[1]).toMatchObject({
      oldPath: "b.txt",
      newPath: "b.txt",
    });
  });

  it("uses parsePatchFiles when only patch is present", () => {
    parsePatchFiles.mockReturnValue([
      {
        files: [
          { name: "a.txt", prevName: "a.txt", hunks: [] },
          { name: "b.txt", prevName: "b.txt", hunks: [] },
        ],
      },
    ]);

    const renderedFiles = buildRenderedFiles({
      identifier: "document-patch",
      patch: "diff --git a/a.txt b/a.txt",
    });

    expect(parsePatchFiles).toHaveBeenCalledWith("diff --git a/a.txt b/a.txt");
    expect(parseDiffFromFile).not.toHaveBeenCalled();
    expect(renderedFiles).toHaveLength(2);
  });
});
