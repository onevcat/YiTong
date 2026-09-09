import { describe, expect, it } from "vitest";
import {
  annotationsForFile,
  buildAnnotationActivatedPayload,
  groupAnnotationsByFile,
  mapAnnotationSide,
} from "./annotationModel";
import type { AnnotationPayload } from "./protocol";

const thread: AnnotationPayload = {
  id: "thread-1",
  fileIndex: 0,
  side: "new",
  lineNumber: 7,
  kind: "discussion",
  html: "<p>Looks good</p>",
};

const draft: AnnotationPayload = {
  id: "draft-1",
  fileIndex: 1,
  side: "old",
  lineNumber: 3,
  text: "Plain note",
};

describe("mapAnnotationSide", () => {
  it("maps protocol sides onto @pierre/diffs annotation sides", () => {
    expect(mapAnnotationSide("old")).toBe("deletions");
    expect(mapAnnotationSide("new")).toBe("additions");
  });
});

describe("groupAnnotationsByFile", () => {
  it("groups annotations per file with the payload as metadata", () => {
    const grouped = groupAnnotationsByFile([thread, draft], 2);

    expect(annotationsForFile(grouped, 0)).toEqual([
      { side: "additions", lineNumber: 7, metadata: thread },
    ]);
    expect(annotationsForFile(grouped, 1)).toEqual([
      { side: "deletions", lineNumber: 3, metadata: draft },
    ]);
  });

  it("keeps multiple annotations on the same line in host order", () => {
    const second: AnnotationPayload = { ...thread, id: "thread-2" };
    const grouped = groupAnnotationsByFile([thread, second], 1);

    expect(annotationsForFile(grouped, 0).map((annotation) => annotation.metadata.id)).toEqual([
      "thread-1",
      "thread-2",
    ]);
  });

  it("drops annotations that point outside the rendered files", () => {
    const stale: AnnotationPayload = { ...thread, id: "stale", fileIndex: 5 };
    const negative: AnnotationPayload = { ...thread, id: "negative", fileIndex: -1 };
    const grouped = groupAnnotationsByFile([thread, stale, negative], 1);

    expect(grouped.size).toBe(1);
    expect(annotationsForFile(grouped, 0)).toHaveLength(1);
    expect(annotationsForFile(grouped, 5)).toEqual([]);
  });

  it("returns an empty map when the host sends no annotations", () => {
    expect(groupAnnotationsByFile([], 3).size).toBe(0);
  });
});

describe("buildAnnotationActivatedPayload", () => {
  it("echoes the annotation coordinates alongside the host action", () => {
    expect(buildAnnotationActivatedPayload(thread, "reply")).toEqual({
      id: "thread-1",
      action: "reply",
      kind: "discussion",
      fileIndex: 0,
      side: "new",
      lineNumber: 7,
    });
  });

  it("omits kind when the annotation has none", () => {
    expect(buildAnnotationActivatedPayload(draft, "dismiss").kind).toBeUndefined();
  });
});
