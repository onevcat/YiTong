import {
  PROTOCOL_VERSION,
  RENDERER_VERSION,
  type Envelope,
  type IncomingMessageType,
  type OutgoingMessageType,
  type ReadyPayload,
  type RenderStateChangedPayload,
} from "./protocol";

declare global {
  interface Window {
    __yitongReceiveMessage?: (message: string) => Promise<void>;
    webkit?: {
      messageHandlers?: {
        yitongBridge?: {
          postMessage(message: string): void;
        };
      };
    };
  }
}

type IncomingHandler = (envelope: Envelope<IncomingMessageType, unknown>) => Promise<void> | void;

let nextEventID = 0;
let incomingHandler: IncomingHandler | undefined;

function nextID(): string {
  nextEventID += 1;
  return `evt-${nextEventID}`;
}

function postToNative<TPayload>(type: OutgoingMessageType, payload: TPayload) {
  const envelope: Envelope<OutgoingMessageType, TPayload> = {
    protocolVersion: PROTOCOL_VERSION,
    id: nextID(),
    type,
    payload,
  };
  const message = JSON.stringify(envelope);

  window.webkit?.messageHandlers?.yitongBridge?.postMessage(message);
}

export function postReady() {
  const payload: ReadyPayload = {
    rendererVersion: RENDERER_VERSION,
  };

  postToNative("ready", payload);
}

export function postRenderStateChanged(payload: RenderStateChangedPayload) {
  postToNative("renderStateChanged", payload);
}

export function installMessageReceiver(handler: IncomingHandler) {
  incomingHandler = handler;
  window.__yitongReceiveMessage = async (message: string) => {
    const envelope = JSON.parse(message) as Envelope<IncomingMessageType, unknown>;
    await incomingHandler?.(envelope);
  };
}
