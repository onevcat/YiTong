import "./styles.css";
import { installMessageReceiver, postReady } from "./bridge";
import { cancelActiveSelection, handleIncomingMessage, handleMessageError } from "./renderer";
import { installTouchLineSelectionSupport } from "./touchLineSelection";

installMessageReceiver(async (envelope) => {
  try {
    await handleIncomingMessage(envelope);
  } catch (error) {
    handleMessageError(error);
  }
});

installTouchLineSelectionSupport({ onSelectionCancelled: cancelActiveSelection });

postReady();
