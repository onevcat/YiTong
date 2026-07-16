import { describe, expect, it } from "vitest";
import { applyDiffTypography, resolveDiffTypography } from "./theme";

describe("resolveDiffTypography", () => {
  it("keeps renderer defaults when no valid override is provided", () => {
    expect(resolveDiffTypography()).toBeNull();
    expect(resolveDiffTypography(0)).toBeNull();
    expect(resolveDiffTypography(-1)).toBeNull();
    expect(resolveDiffTypography(0.5)).toBeNull();
    expect(resolveDiffTypography(513)).toBeNull();
    expect(resolveDiffTypography(Number.NaN)).toBeNull();
    expect(resolveDiffTypography(Number.POSITIVE_INFINITY)).toBeNull();
  });

  it("scales font size and line height using the renderer default ratio", () => {
    expect(resolveDiffTypography(13)).toEqual({
      fontSize: "13px",
      lineHeight: "20px",
    });
    expect(resolveDiffTypography(18)).toEqual({
      fontSize: "18px",
      lineHeight: "27.692px",
    });
  });

  it("applies and removes renderer CSS variables", () => {
    const properties = new Map<string, string>();
    const element = {
      style: {
        setProperty(name: string, value: string) {
          properties.set(name, value);
        },
        removeProperty(name: string) {
          properties.delete(name);
        },
      },
    } as unknown as HTMLElement;

    applyDiffTypography(element, 18);
    expect(properties.get("--diffs-font-size")).toBe("18px");
    expect(properties.get("--diffs-line-height")).toBe("27.692px");

    applyDiffTypography(element, undefined);
    expect(properties.has("--diffs-font-size")).toBe(false);
    expect(properties.has("--diffs-line-height")).toBe(false);
  });
});
