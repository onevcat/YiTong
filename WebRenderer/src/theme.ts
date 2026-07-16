import type { InlineChangeStyle, RenderConfigurationPayload, ResolvedAppearance } from "./protocol";

const defaultDiffFontSize = 13;
const defaultDiffLineHeight = 20;

export interface DiffTypography {
  fontSize: string;
  lineHeight: string;
}

function pixelValue(value: number): string {
  return `${Number(value.toFixed(3))}px`;
}

export function resolveDiffTypography(fontSize?: number): DiffTypography | null {
  if (fontSize == null || !Number.isFinite(fontSize) || fontSize < 1 || fontSize > 512) {
    return null;
  }

  return {
    fontSize: pixelValue(fontSize),
    lineHeight: pixelValue(fontSize * defaultDiffLineHeight / defaultDiffFontSize),
  };
}

export function applyDiffTypography(element: HTMLElement, fontSize?: number) {
  const typography = resolveDiffTypography(fontSize);
  if (typography == null) {
    element.style.removeProperty("--diffs-font-size");
    element.style.removeProperty("--diffs-line-height");
    return;
  }

  element.style.setProperty("--diffs-font-size", typography.fontSize);
  element.style.setProperty("--diffs-line-height", typography.lineHeight);
}

export function resolveThemeType(appearance: ResolvedAppearance): "light" | "dark" {
  return appearance;
}

export function resolveLineDiffType(style: InlineChangeStyle): "word-alt" | "word" | "char" | "none" {
  switch (style) {
    case "wordAlt":
      return "word-alt";
    case "word":
      return "word";
    case "char":
      return "char";
    case "none":
      return "none";
  }
}

export function toDiffOptions(configuration: RenderConfigurationPayload) {
  return {
    theme: {
      dark: "pierre-dark",
      light: "pierre-light",
    },
    themeType: resolveThemeType(configuration.resolvedAppearance),
    diffStyle: configuration.diffStyle,
    diffIndicators: configuration.diffIndicators,
    disableBackground: !configuration.showsChangeBackgrounds,
    disableLineNumbers: !configuration.showsLineNumbers,
    overflow: configuration.wrapsLines ? "wrap" : "scroll",
    disableFileHeader: !configuration.showsFileHeaders,
    lineDiffType: resolveLineDiffType(configuration.inlineChangeStyle),
    enableLineSelection: configuration.allowsSelection,
  } as const;
}
