const textEncoder = new TextEncoder();
const textDecoder = new TextDecoder("utf-8", { fatal: true });
const patchControlPattern = /[\u0000-\u001f\u007f-\u009f\u2028\u2029]/u;

interface PathToken {
  value: string;
  endIndex: number;
  quoted: boolean;
}

/**
 * Decodes Git's C-quoted UTF-8 paths before handing a patch to @pierre/diffs.
 * Only file headers are touched; hunk contents remain byte-for-byte intact.
 */
export function normalizeGitPatchPaths(patch: string): string {
  let inFileHeader = false;
  const lines = patch.match(/[^\n]*\n|[^\n]+$/g) ?? [];

  return lines
    .map((rawLine) => {
      const { line, ending } = splitLineEnding(rawLine);

      if (line.startsWith("diff --git ")) {
        inFileHeader = true;
        return normalizeDiffHeader(line) + ending;
      }
      if (line.startsWith("@@ ")) {
        inFileHeader = false;
        return rawLine;
      }
      if (!inFileHeader) {
        return rawLine;
      }

      for (const prefix of [
        "--- ",
        "+++ ",
        "rename from ",
        "rename to ",
        "copy from ",
        "copy to ",
      ]) {
        if (line.startsWith(prefix)) {
          return normalizeSinglePathLine(line, prefix) + ending;
        }
      }
      return rawLine;
    })
    .join("");
}

function normalizeDiffHeader(line: string): string {
  const prefix = "diff --git ";
  let index = prefix.length;
  const oldPath = readPathToken(line, index);
  if (oldPath == null) {
    return line;
  }
  index = skipSpaces(line, oldPath.endIndex);
  if (index == oldPath.endIndex) {
    return line;
  }
  const newPath = readPathToken(line, index);
  if (newPath == null || line.slice(newPath.endIndex).trim().length > 0) {
    return line;
  }
  if (!oldPath.quoted && !newPath.quoted) {
    return line;
  }

  return `${prefix}${formatDiffToken(oldPath)} ${formatDiffToken(newPath)}${line.slice(newPath.endIndex)}`;
}

function normalizeSinglePathLine(line: string, prefix: string): string {
  const token = readPathToken(line, prefix.length);
  if (token == null || !token.quoted) {
    return line;
  }
  return `${prefix}${token.value}${line.slice(token.endIndex)}`;
}

function readPathToken(input: string, startIndex: number): PathToken | null {
  if (input[startIndex] !== '"') {
    let endIndex = startIndex;
    while (endIndex < input.length && input[endIndex] !== " " && input[endIndex] !== "\t") {
      endIndex += 1;
    }
    return endIndex == startIndex
      ? null
      : { value: input.slice(startIndex, endIndex), endIndex, quoted: false };
  }

  const bytes: number[] = [];
  let index = startIndex + 1;
  while (index < input.length) {
    const character = input[index];
    if (character === '"') {
      try {
        const value = textDecoder.decode(Uint8Array.from(bytes));
        if (patchControlPattern.test(value)) {
          // Do not inject control characters or Unicode line separators into
          // patch grammar, even if a nonstandard producer left them unescaped.
          return null;
        }
        return {
          value,
          endIndex: index + 1,
          quoted: true,
        };
      } catch {
        // Git paths are byte strings and are not required to be UTF-8. Leave
        // an undecodable quoted token untouched for @pierre/diffs to parse.
        return null;
      }
    }

    if (character !== "\\") {
      const codePoint = input.codePointAt(index);
      if (codePoint == null) {
        return null;
      }
      const scalar = String.fromCodePoint(codePoint);
      bytes.push(...textEncoder.encode(scalar));
      index += scalar.length;
      continue;
    }

    const escaped = input[index + 1];
    if (escaped == null) {
      return null;
    }
    if (/[0-7]/.test(escaped)) {
      let octal = "";
      index += 1;
      while (index < input.length && octal.length < 3 && /[0-7]/.test(input[index]!)) {
        octal += input[index];
        index += 1;
      }
      const value = Number.parseInt(octal, 8);
      if (value < 0x20 || value === 0x7f || value > 0xff) {
        // Never turn a quoted path into patch grammar by injecting a control
        // character such as a tab, carriage return, or line feed. Values over
        // one byte would otherwise be truncated by Uint8Array.from.
        return null;
      }
      bytes.push(value);
      continue;
    }

    if (escaped === '"' || escaped === "\\") {
      bytes.push(...textEncoder.encode(escaped));
    } else {
      // Preserve control and unknown escapes in textual form so normalizing a
      // path can never inject tabs or line breaks into the patch grammar.
      bytes.push(...textEncoder.encode(`\\${escaped}`));
    }
    index += 2;
  }
  return null;
}

function formatDiffToken(token: PathToken): string {
  if (!token.quoted) {
    return token.value;
  }
  return `"${token.value.replaceAll("\\", "\\\\").replaceAll('"', '\\"')}"`;
}

function skipSpaces(input: string, startIndex: number): number {
  let index = startIndex;
  while (input[index] === " ") {
    index += 1;
  }
  return index;
}

function splitLineEnding(rawLine: string): { line: string; ending: string } {
  if (rawLine.endsWith("\r\n")) {
    return { line: rawLine.slice(0, -2), ending: "\r\n" };
  }
  if (rawLine.endsWith("\n")) {
    return { line: rawLine.slice(0, -1), ending: "\n" };
  }
  return { line: rawLine, ending: "" };
}
