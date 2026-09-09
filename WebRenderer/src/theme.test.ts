import { describe, expect, it } from "vitest";
import type { RenderConfigurationPayload } from "./protocol";
import { toDiffOptions } from "./theme";
import { LINE_NUMBER_TOUCH_ACTION_CSS } from "./touchLineSelection";

const configuration: RenderConfigurationPayload = {
  diffStyle: "unified",
  diffIndicators: "bars",
  showsLineNumbers: true,
  showsChangeBackgrounds: true,
  wrapsLines: true,
  showsFileHeaders: false,
  inlineChangeStyle: "word",
  allowsSelection: true,
  resolvedAppearance: "dark",
};

describe("toDiffOptions", () => {
  it("opts the interactive line-number gutter out of touch scrolling", () => {
    const options = toDiffOptions(configuration);

    expect(options.unsafeCSS).toBe(LINE_NUMBER_TOUCH_ACTION_CSS);
    expect(options.unsafeCSS).toContain("[data-interactive-line-numbers] [data-column-number]");
    expect(options.unsafeCSS).toContain("touch-action: none");
  });

  it("keeps the gutter rule scoped to interactive line numbers", () => {
    // `data-interactive-line-numbers` is only set when selection is enabled,
    // so the rule must not match a read-only gutter.
    expect(LINE_NUMBER_TOUCH_ACTION_CSS.startsWith("[data-interactive-line-numbers] ")).toBe(true);
  });
});
