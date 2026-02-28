import type { InlineChangeStyle, RenderConfigurationPayload, ResolvedAppearance } from "./protocol";

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
    disableLineNumbers: !configuration.showsLineNumbers,
    overflow: configuration.wrapsLines ? "wrap" : "scroll",
    disableFileHeader: !configuration.showsFileHeaders,
    lineDiffType: resolveLineDiffType(configuration.inlineChangeStyle),
    enableLineSelection: configuration.allowsSelection,
  } as const;
}
