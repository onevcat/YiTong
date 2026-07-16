import { describe, expect, it } from "vitest";
import { buildRenderedFiles } from "./renderDocumentModel";

describe("quoted Git paths", () => {
  it("parses Git C-quoted UTF-8 paths", () => {
    const path = String.raw`notes/\344\270\255\346\226\207.md`;
    const patch = [
      `diff --git "a/${path}" "b/${path}"`,
      "index 1111111..2222222 100644",
      `--- "a/${path}"`,
      `+++ "b/${path}"`,
      "@@ -1 +1 @@",
      "-old",
      "+new",
    ].join("\n");

    const files = buildRenderedFiles({
      identifier: "quoted-git-path",
      patch,
    });

    expect(files).toHaveLength(1);
    expect(files[0]?.newPath).toBe("notes/中文.md");
    expect(files[0]?.fileDiff.hunks).toHaveLength(1);
  });

  it("keeps rendering when a Git path is not valid UTF-8", () => {
    const path = String.raw`\377.md`;
    const patch = [
      `diff --git "a/${path}" "b/${path}"`,
      `--- "a/${path}"`,
      `+++ "b/${path}"`,
      "@@ -1 +1 @@",
      "-old",
      "+new",
    ].join("\n");

    const files = buildRenderedFiles({
      identifier: "non-utf8-git-path",
      patch,
    });

    expect(files).toHaveLength(1);
    expect(files[0]?.newPath).toBe(String.raw`\377.md`);
    expect(files[0]?.fileDiff.hunks).toHaveLength(1);
  });
});
