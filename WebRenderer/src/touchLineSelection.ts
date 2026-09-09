// Touch support for @pierre/diffs line selection.
//
// `LineSelectionManager` listens to pointer events only and resolves the
// hovered line from `event.composedPath()`. Two WebKit behaviors break that
// for touch pointers (iPad), and both fixes below are required together:
//
// 1. The line-number gutter has no `touch-action`, so WebKit treats a finger
//    drag as a scroll gesture and fires `pointercancel`. The gutter must opt
//    out via `touch-action: none` (injected through `unsafeCSS`).
// 2. Touch pointers get implicit pointer capture on `pointerdown`. While
//    captured, every `pointermove` is retargeted to the element that was
//    touched first, so `composedPath()` keeps resolving to the anchor line and
//    the selection never extends. The capture has to be released before the
//    manager's own handler runs.

export const LINE_NUMBER_TOUCH_ACTION_CSS =
  "[data-interactive-line-numbers] [data-column-number] { touch-action: none; }";

interface AttributeHolder {
  hasAttribute(name: string): boolean;
}

interface PointerCaptureHolder {
  hasPointerCapture(pointerId: number): boolean;
  releasePointerCapture(pointerId: number): void;
}

interface PointerLikeEvent extends Event {
  pointerId: number;
  pointerType: string;
}

export interface TouchLineSelectionOptions {
  target?: EventTarget;
  onSelectionCancelled(event: PointerLikeEvent): void;
}

function isAttributeHolder(node: unknown): node is AttributeHolder {
  return typeof (node as Partial<AttributeHolder> | null)?.hasAttribute === "function";
}

function isPointerCaptureHolder(node: unknown): node is PointerCaptureHolder {
  const candidate = node as Partial<PointerCaptureHolder> | null;
  return (
    typeof candidate?.hasPointerCapture === "function" &&
    typeof candidate?.releasePointerCapture === "function"
  );
}

function isPointerLikeEvent(event: Event): event is PointerLikeEvent {
  const candidate = event as Partial<PointerLikeEvent>;
  return typeof candidate.pointerId === "number" && typeof candidate.pointerType === "string";
}

// Mirrors the gutter detection in `LineSelectionManager.getMouseEventDataForPath`.
export function pathTargetsLineNumberColumn(path: readonly EventTarget[]): boolean {
  return path.some((node) => isAttributeHolder(node) && node.hasAttribute("data-column-number"));
}

export function installTouchLineSelectionSupport(options: TouchLineSelectionOptions): () => void {
  const target = options.target ?? document;
  let activePointerId: number | undefined;

  const handlePointerDown = (event: Event) => {
    if (!isPointerLikeEvent(event) || event.pointerType !== "touch") {
      return;
    }

    const path = event.composedPath();
    if (!pathTargetsLineNumberColumn(path)) {
      return;
    }

    const origin = path[0];
    if (isPointerCaptureHolder(origin) && origin.hasPointerCapture(event.pointerId)) {
      origin.releasePointerCapture(event.pointerId);
    }
    activePointerId = event.pointerId;
  };

  const handlePointerUp = (event: Event) => {
    if (isPointerLikeEvent(event) && event.pointerId === activePointerId) {
      activePointerId = undefined;
    }
  };

  const handlePointerCancel = (event: Event) => {
    if (!isPointerLikeEvent(event) || event.pointerId !== activePointerId) {
      return;
    }

    activePointerId = undefined;
    options.onSelectionCancelled(event);
  };

  // Capture phase so the release happens before `LineSelectionManager` sees the event.
  target.addEventListener("pointerdown", handlePointerDown, { capture: true });
  target.addEventListener("pointerup", handlePointerUp, { capture: true });
  target.addEventListener("pointercancel", handlePointerCancel, { capture: true });

  return () => {
    target.removeEventListener("pointerdown", handlePointerDown, { capture: true });
    target.removeEventListener("pointerup", handlePointerUp, { capture: true });
    target.removeEventListener("pointercancel", handlePointerCancel, { capture: true });
  };
}
