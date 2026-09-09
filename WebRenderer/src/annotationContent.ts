import type { AnnotationPayload } from "./protocol";

export const ANNOTATION_CLASS_NAME = "yitong-annotation";
export const ANNOTATION_ACTION_ATTRIBUTE = "data-action";

const SCRIPT_BEARING_SELECTOR = "script, iframe, object, embed";
const URL_ATTRIBUTES = new Set(["href", "src", "xlink:href", "action", "formaction"]);

/**
 * Builds the light-DOM element that `@pierre/diffs` slots beneath the line.
 *
 * The host is responsible for the content it sends. The renderer only removes
 * script execution vectors so an annotation can never run code inside the
 * WKWebView; everything else (markup, inline styles, `data-action` hooks) is
 * preserved verbatim.
 */
export function createAnnotationContentElement(annotation: AnnotationPayload): HTMLElement {
  const element = document.createElement("div");
  element.className = ANNOTATION_CLASS_NAME;
  element.dataset.annotationId = annotation.id;
  if (annotation.kind != null) {
    element.dataset.annotationKind = annotation.kind;
  }

  if (annotation.html != null) {
    element.appendChild(sanitizeHTML(annotation.html));
  } else {
    element.textContent = annotation.text ?? "";
  }

  return element;
}

export function sanitizeHTML(html: string): DocumentFragment {
  // `<template>` parses into an inert document, so nothing executes while parsing.
  const template = document.createElement("template");
  template.innerHTML = html;

  for (const node of Array.from(template.content.querySelectorAll(SCRIPT_BEARING_SELECTOR))) {
    node.remove();
  }

  for (const element of Array.from(template.content.querySelectorAll("*"))) {
    for (const attribute of Array.from(element.attributes)) {
      const name = attribute.name.toLowerCase();
      if (name.startsWith("on") || (URL_ATTRIBUTES.has(name) && /^\s*javascript:/i.test(attribute.value))) {
        element.removeAttribute(attribute.name);
      }
    }
  }

  return template.content;
}

export interface ActivatedAction {
  annotationID: string;
  action: string;
}

/**
 * Resolves a click inside an annotation to the `data-action` the host attached.
 * Annotation elements live in the light DOM, so `closest` works without
 * crossing the shadow boundary of the diff container.
 */
export function resolveActivatedAction(target: EventTarget | null): ActivatedAction | undefined {
  if (!(target instanceof Element)) {
    return undefined;
  }

  const actionElement = target.closest<HTMLElement>(`[${ANNOTATION_ACTION_ATTRIBUTE}]`);
  const action = actionElement?.getAttribute(ANNOTATION_ACTION_ATTRIBUTE);
  if (actionElement == null || action == null || action.length === 0) {
    return undefined;
  }

  const annotationID = actionElement.closest<HTMLElement>(`.${ANNOTATION_CLASS_NAME}`)?.dataset.annotationId;
  if (annotationID == null) {
    return undefined;
  }

  return { annotationID, action };
}
