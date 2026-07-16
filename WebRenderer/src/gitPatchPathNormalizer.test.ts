import { describe, expect, it } from "vitest";
import { normalizeGitPatchPaths } from "./gitPatchPathNormalizer";

describe("normalizeGitPatchPaths", () => {
  it("decodes quoted UTF-8 paths in Git file headers", () => {
    const escaped = String.raw`notes/\344\270\255\346\226\207.md`;
    const patch = [
      `diff --git "a/${escaped}" "b/${escaped}"`,
      `--- "a/${escaped}"`,
      `+++ "b/${escaped}"`,
    ].join("\n");

    expect(normalizeGitPatchPaths(patch)).toBe(
      [
        'diff --git "a/notes/中文.md" "b/notes/中文.md"',
        "--- a/notes/中文.md",
        "+++ b/notes/中文.md",
      ].join("\n"),
    );
  });

  it("handles either side of a Git header being quoted", () => {
    expect(
      normalizeGitPatchPaths(String.raw`diff --git "a/\346\227\247.md" b/new.md`),
    ).toBe('diff --git "a/旧.md" b/new.md');
    expect(
      normalizeGitPatchPaths(String.raw`diff --git a/old.md "b/\346\226\260.md"`),
    ).toBe('diff --git a/old.md "b/新.md"');
  });

  it("decodes quoted rename and copy paths", () => {
    const patch = [
      String.raw`diff --git "a/\346\227\247.md" "b/\346\226\260.md"`,
      String.raw`rename from "\346\227\247.md"`,
      String.raw`rename to "\346\226\260.md"`,
      String.raw`copy from "\346\227\247.md"`,
      String.raw`copy to "\346\226\260.md"`,
    ].join("\n");

    expect(normalizeGitPatchPaths(patch)).toBe(
      [
        'diff --git "a/旧.md" "b/新.md"',
        "rename from 旧.md",
        "rename to 新.md",
        "copy from 旧.md",
        "copy to 新.md",
      ].join("\n"),
    );
  });

  it("leaves non-UTF-8 quoted paths unchanged", () => {
    const patch = [
      String.raw`diff --git "a/\377.md" "b/\377.md"`,
      String.raw`--- "a/\377.md"`,
      String.raw`+++ "b/\377.md"`,
    ].join("\n");

    expect(normalizeGitPatchPaths(patch)).toBe(patch);
  });

  it.each(["011", "012", "015"])(
    "does not inject an octal control byte \\%s into patch grammar",
    (octal) => {
      const escapedPath = `\\${octal}.md`;
      const patch = [
        `diff --git "a/${escapedPath}" "b/${escapedPath}"`,
        `--- "a/${escapedPath}"`,
        `+++ "b/${escapedPath}"`,
      ].join("\n");

      expect(normalizeGitPatchPaths(patch)).toBe(patch);
    },
  );

  it.each(["400", "411"])(
    "does not truncate an overflowing octal value \\%s into one byte",
    (octal) => {
      const escapedPath = `\\${octal}.md`;
      const patch = `diff --git "a/${escapedPath}" "b/${escapedPath}"`;

      expect(normalizeGitPatchPaths(patch)).toBe(patch);
    },
  );

  it.each([
    String.raw`\302\205`,
    String.raw`\342\200\250`,
    String.raw`\342\200\251`,
  ])(
    "does not inject a Unicode control or line separator encoded as %s",
    (escapedPath) => {
      const patch = `diff --git "a/${escapedPath}" "b/${escapedPath}"`;

      expect(normalizeGitPatchPaths(patch)).toBe(patch);
    },
  );

  it("does not rewrite hunk content that resembles a file header", () => {
    const patch = [
      "diff --git a/example.md b/example.md",
      "--- a/example.md",
      "+++ b/example.md",
      "@@ -1 +1 @@",
      String.raw`--- "not-a-header"`,
      "+replacement",
    ].join("\n");

    expect(normalizeGitPatchPaths(patch)).toBe(patch);
  });
});
