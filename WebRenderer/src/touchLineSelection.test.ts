import { describe, expect, it, vi } from "vitest";
import { installTouchLineSelectionSupport, pathTargetsLineNumberColumn } from "./touchLineSelection";

class FakeElement extends EventTarget {
  private readonly attributes = new Set<string>();
  private readonly capturedPointers = new Set<number>();

  constructor(attributes: string[] = []) {
    super();
    for (const attribute of attributes) {
      this.attributes.add(attribute);
    }
  }

  hasAttribute(name: string) {
    return this.attributes.has(name);
  }

  capturePointer(pointerId: number) {
    this.capturedPointers.add(pointerId);
  }

  hasPointerCapture(pointerId: number) {
    return this.capturedPointers.has(pointerId);
  }

  releasePointerCapture(pointerId: number) {
    this.capturedPointers.delete(pointerId);
  }
}

class FakePointerEvent extends Event {
  constructor(
    type: string,
    readonly pointerId: number,
    readonly pointerType: string,
    private readonly path: EventTarget[],
  ) {
    super(type);
  }

  override composedPath() {
    return this.path;
  }
}

function makeGutterPath(target: EventTarget) {
  return [new FakeElement(["data-column-number"]), new FakeElement(["data-line"]), target];
}

describe("pathTargetsLineNumberColumn", () => {
  it("detects the line-number column anywhere in the path", () => {
    expect(pathTargetsLineNumberColumn(makeGutterPath(new EventTarget()))).toBe(true);
  });

  it("ignores paths without the line-number column", () => {
    expect(pathTargetsLineNumberColumn([new FakeElement(["data-line"]), new EventTarget()])).toBe(false);
  });
});

describe("installTouchLineSelectionSupport", () => {
  function setup() {
    const target = new EventTarget();
    const onSelectionCancelled = vi.fn();
    const uninstall = installTouchLineSelectionSupport({ target, onSelectionCancelled });
    return { target, onSelectionCancelled, uninstall };
  }

  it("releases implicit capture for touch pointers that start in the gutter", () => {
    const { target } = setup();
    const origin = new FakeElement(["data-column-number"]);
    origin.capturePointer(7);

    target.dispatchEvent(new FakePointerEvent("pointerdown", 7, "touch", [origin, target]));

    expect(origin.hasPointerCapture(7)).toBe(false);
  });

  it("leaves mouse pointers untouched", () => {
    const { target } = setup();
    const origin = new FakeElement(["data-column-number"]);
    origin.capturePointer(1);

    target.dispatchEvent(new FakePointerEvent("pointerdown", 1, "mouse", [origin, target]));

    expect(origin.hasPointerCapture(1)).toBe(true);
  });

  it("leaves touches outside the gutter untouched", () => {
    const { target } = setup();
    const origin = new FakeElement(["data-line"]);
    origin.capturePointer(7);

    target.dispatchEvent(new FakePointerEvent("pointerdown", 7, "touch", [origin, target]));

    expect(origin.hasPointerCapture(7)).toBe(true);
  });

  it("reports pointercancel only for the gutter touch that is in flight", () => {
    const { target, onSelectionCancelled } = setup();
    const origin = new FakeElement(["data-column-number"]);

    target.dispatchEvent(new FakePointerEvent("pointercancel", 7, "touch", [origin, target]));
    expect(onSelectionCancelled).not.toHaveBeenCalled();

    target.dispatchEvent(new FakePointerEvent("pointerdown", 7, "touch", [origin, target]));
    target.dispatchEvent(new FakePointerEvent("pointercancel", 8, "touch", [origin, target]));
    expect(onSelectionCancelled).not.toHaveBeenCalled();

    target.dispatchEvent(new FakePointerEvent("pointercancel", 7, "touch", [origin, target]));
    expect(onSelectionCancelled).toHaveBeenCalledTimes(1);
    expect(onSelectionCancelled.mock.calls[0][0].pointerId).toBe(7);
  });

  it("forgets the gutter touch once it ends normally", () => {
    const { target, onSelectionCancelled } = setup();
    const origin = new FakeElement(["data-column-number"]);

    target.dispatchEvent(new FakePointerEvent("pointerdown", 7, "touch", [origin, target]));
    target.dispatchEvent(new FakePointerEvent("pointerup", 7, "touch", [origin, target]));
    target.dispatchEvent(new FakePointerEvent("pointercancel", 7, "touch", [origin, target]));

    expect(onSelectionCancelled).not.toHaveBeenCalled();
  });

  it("stops listening after uninstall", () => {
    const { target, onSelectionCancelled, uninstall } = setup();
    const origin = new FakeElement(["data-column-number"]);
    uninstall();

    target.dispatchEvent(new FakePointerEvent("pointerdown", 7, "touch", [origin, target]));
    target.dispatchEvent(new FakePointerEvent("pointercancel", 7, "touch", [origin, target]));

    expect(onSelectionCancelled).not.toHaveBeenCalled();
  });
});
