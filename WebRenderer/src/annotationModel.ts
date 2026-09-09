import type { AnnotationSide as DiffsAnnotationSide, DiffLineAnnotation } from "@pierre/diffs";
import type { AnnotationActivatedPayload, AnnotationPayload, AnnotationSide } from "./protocol";

export type LineAnnotationForFile = DiffLineAnnotation<AnnotationPayload>;

export function mapAnnotationSide(side: AnnotationSide): DiffsAnnotationSide {
  switch (side) {
    case "old":
      return "deletions";
    case "new":
      return "additions";
  }
}

/**
 * Groups host annotations by file index in the shape `FileDiff.render` expects.
 * Annotations pointing outside `fileCount` are dropped so a stale annotation
 * list can never break rendering of the diff itself.
 */
export function groupAnnotationsByFile(
  annotations: readonly AnnotationPayload[],
  fileCount: number,
): Map<number, LineAnnotationForFile[]> {
  const grouped = new Map<number, LineAnnotationForFile[]>();

  for (const annotation of annotations) {
    if (!Number.isInteger(annotation.fileIndex) || annotation.fileIndex < 0 || annotation.fileIndex >= fileCount) {
      continue;
    }

    const list = grouped.get(annotation.fileIndex) ?? [];
    list.push({
      side: mapAnnotationSide(annotation.side),
      lineNumber: annotation.lineNumber,
      metadata: annotation,
    });
    grouped.set(annotation.fileIndex, list);
  }

  return grouped;
}

export function annotationsForFile(
  grouped: Map<number, LineAnnotationForFile[]>,
  fileIndex: number,
): LineAnnotationForFile[] {
  return grouped.get(fileIndex) ?? [];
}

export function buildAnnotationActivatedPayload(
  annotation: AnnotationPayload,
  action: string,
): AnnotationActivatedPayload {
  return {
    id: annotation.id,
    action,
    kind: annotation.kind,
    fileIndex: annotation.fileIndex,
    side: annotation.side,
    lineNumber: annotation.lineNumber,
  };
}
