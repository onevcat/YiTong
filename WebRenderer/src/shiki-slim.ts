/**
 * Slim shiki shim — re-exports the full API surface but bundles only a curated
 * set of ~47 languages instead of all 371+.  Vite alias `shiki` → this file.
 *
 * When a language not in the subset is requested at runtime,
 * `@pierre/diffs` will throw "No valid loader for <lang>" and fall back to
 * plain-text rendering — acceptable for a diff viewer.
 */

// ── Core API (everything @pierre/diffs needs except bundledLanguages/Themes) ──
export * from "@shikijs/core";
export {
  createJavaScriptRegexEngine,
  defaultJavaScriptRegexConstructor,
} from "@shikijs/engine-javascript";

// @pierre/diffs also imports this optional API for its WASM mode. YiTong
// always requests `shiki-js`, so exporting a throwing stub preserves the slim
// bundle without pulling an unused WASM runtime into the app.
export async function createOnigurumaEngine(..._args: unknown[]): Promise<never> {
  throw new Error("YiTong embeds the JavaScript Shiki engine, not the WASM engine");
}

// ── Curated language set ─────────────────────────────────────────────────────
// Apple / systems
import swift from "@shikijs/langs/swift";
import objectiveC from "@shikijs/langs/objective-c";
import c from "@shikijs/langs/c";
import cpp from "@shikijs/langs/cpp";
import java from "@shikijs/langs/java";
import kotlin from "@shikijs/langs/kotlin";

// Web
import javascript from "@shikijs/langs/javascript";
import typescript from "@shikijs/langs/typescript";
import jsx from "@shikijs/langs/jsx";
import tsx from "@shikijs/langs/tsx";
import html from "@shikijs/langs/html";
import css from "@shikijs/langs/css";
import scss from "@shikijs/langs/scss";
import vue from "@shikijs/langs/vue";

// Scripting
import python from "@shikijs/langs/python";
import ruby from "@shikijs/langs/ruby";
import go from "@shikijs/langs/go";
import rust from "@shikijs/langs/rust";
import php from "@shikijs/langs/php";
import lua from "@shikijs/langs/lua";
import shellscript from "@shikijs/langs/shellscript";
// Dropped: powershell (21KB)

// Config / data
import json from "@shikijs/langs/json";
import jsonc from "@shikijs/langs/jsonc";
import yaml from "@shikijs/langs/yaml";
import toml from "@shikijs/langs/toml";
import xml from "@shikijs/langs/xml";
import ini from "@shikijs/langs/ini";
import dotenv from "@shikijs/langs/dotenv";

// Misc
import markdown from "@shikijs/langs/markdown";
import sql from "@shikijs/langs/sql";
import graphql from "@shikijs/langs/graphql";
import proto from "@shikijs/langs/proto";
import groovy from "@shikijs/langs/groovy";
import dockerfile from "@shikijs/langs/dockerfile";
import diff from "@shikijs/langs/diff";
import makefile from "@shikijs/langs/makefile";
import cmake from "@shikijs/langs/cmake";
import csharp from "@shikijs/langs/csharp";
import dart from "@shikijs/langs/dart";
// Dropped: elixir (18KB), scala (31KB), haskell (45KB)
import r from "@shikijs/langs/r";
import zig from "@shikijs/langs/zig";

// Map each language id (and known aliases) → dynamic-import-shaped loader.
// @pierre/diffs calls  `bundledLanguages[id]()` and destructures `{ default: data }`,
// so we must wrap the grammar in an ESM-module-shaped object.
function wrapSync(mod: unknown) {
  return () => Promise.resolve({ default: mod });
}

export const bundledLanguagesBase: Record<string, () => Promise<unknown>> = {
  swift: wrapSync(swift),
  "objective-c": wrapSync(objectiveC),
  c: wrapSync(c),
  cpp: wrapSync(cpp),
  java: wrapSync(java),
  kotlin: wrapSync(kotlin),
  javascript: wrapSync(javascript),
  typescript: wrapSync(typescript),
  jsx: wrapSync(jsx),
  tsx: wrapSync(tsx),
  html: wrapSync(html),
  css: wrapSync(css),
  scss: wrapSync(scss),
  vue: wrapSync(vue),
  python: wrapSync(python),
  ruby: wrapSync(ruby),
  go: wrapSync(go),
  rust: wrapSync(rust),
  php: wrapSync(php),
  lua: wrapSync(lua),
  shellscript: wrapSync(shellscript),
  json: wrapSync(json),
  jsonc: wrapSync(jsonc),
  yaml: wrapSync(yaml),
  toml: wrapSync(toml),
  xml: wrapSync(xml),
  ini: wrapSync(ini),
  dotenv: wrapSync(dotenv),
  markdown: wrapSync(markdown),
  sql: wrapSync(sql),
  graphql: wrapSync(graphql),
  proto: wrapSync(proto),
  groovy: wrapSync(groovy),
  dockerfile: wrapSync(dockerfile),
  diff: wrapSync(diff),
  makefile: wrapSync(makefile),
  cmake: wrapSync(cmake),
  csharp: wrapSync(csharp),
  dart: wrapSync(dart),
  r: wrapSync(r),
  zig: wrapSync(zig),
};

// Aliases (file-extension or short names → same loader as the canonical id)
export const bundledLanguagesAlias: Record<string, () => Promise<unknown>> = {
  "c++": wrapSync(cpp),
  "c#": wrapSync(csharp),
  cs: wrapSync(csharp),
  objc: wrapSync(objectiveC),
  gql: wrapSync(graphql),
  protobuf: wrapSync(proto),
  properties: wrapSync(ini),
  js: wrapSync(javascript),
  cjs: wrapSync(javascript),
  mjs: wrapSync(javascript),
  kt: wrapSync(kotlin),
  kts: wrapSync(kotlin),
  md: wrapSync(markdown),
  py: wrapSync(python),
  rb: wrapSync(ruby),
  rs: wrapSync(rust),
  ts: wrapSync(typescript),
  cts: wrapSync(typescript),
  mts: wrapSync(typescript),
  yml: wrapSync(yaml),
  // Shell aliases used by @pierre/diffs extension map
  shell: wrapSync(shellscript),
  bash: wrapSync(shellscript),
  sh: wrapSync(shellscript),
  zsh: wrapSync(shellscript),
};

export const bundledLanguages: Record<string, () => Promise<unknown>> = {
  ...bundledLanguagesBase,
  ...bundledLanguagesAlias,
};

export const bundledLanguagesInfo: {
  id: string;
  name: string;
  aliases?: string[];
  import: () => Promise<unknown>;
}[] = []; // Not used by @pierre/diffs at runtime — safe to leave empty.

// ── Themes ───────────────────────────────────────────────────────────────────
// @pierre/diffs registers "pierre-dark" and "pierre-light" as custom CSS
// variable themes.  bundledThemes is only a fallback lookup, so an empty
// object is fine.
export const bundledThemes: Record<string, () => Promise<unknown>> = {};
export const bundledThemesInfo: unknown[] = [];

// ── createHighlighter (bundled variant) ──────────────────────────────────────
import {
  createBundledHighlighter,
  guessEmbeddedLanguages,
  createSingletonShorthands,
} from "@shikijs/core";

export const createHighlighter = /* @__PURE__ */ createBundledHighlighter({
  langs: bundledLanguages as any,
  themes: bundledThemes as any,
  engine: () =>
    createJavaScriptRegexEngine() as any,
});

// ── Singleton shorthands (codeToHtml, etc.) ──────────────────────────────────
const _shorthands = /* @__PURE__ */ createSingletonShorthands(
  createHighlighter as any,
  { guessEmbeddedLanguages },
);

export const codeToHtml = _shorthands.codeToHtml;
export const codeToHast = _shorthands.codeToHast;
export const codeToTokens = _shorthands.codeToTokens;
export const codeToTokensBase = _shorthands.codeToTokensBase;
export const codeToTokensWithThemes = _shorthands.codeToTokensWithThemes;
export const getSingletonHighlighter = _shorthands.getSingletonHighlighter;
export const getLastGrammarState = _shorthands.getLastGrammarState;
