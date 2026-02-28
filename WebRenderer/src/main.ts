import "./styles.css";
import { installMessageReceiver, postReady } from "./bridge";
import { handleIncomingMessage, handleMessageError } from "./renderer";

installMessageReceiver(async (envelope) => {
  try {
    await handleIncomingMessage(envelope);
  } catch (error) {
    handleMessageError(error);
  }
});

postReady();
