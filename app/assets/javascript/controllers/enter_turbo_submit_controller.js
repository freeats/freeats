import { Controller } from "@hotwired/stimulus";
import { requestSubmitPolyfilled, eventFromRichText } from "../src/shared/input_utils";

export default class extends Controller {
  static targets = ["shortcut"];

  connect() {
    this.element.addEventListener("keydown", (event) => {
      // Don't prevent default 'enter' behaviour for rich text areas.
      if (event.code === "Enter" && !eventFromRichText(event)) {
        event.preventDefault();
      }

      if ((event.metaKey || event.ctrlKey) && event.code === "Enter") {
        requestSubmitPolyfilled(this.element);
      }
    });
  }

  shortcutTargetConnected(elem) {
    if (navigator.userAgent.indexOf("Mac") !== -1) {
      elem.setAttribute("data-bs-title", "⌘Cmd + Enter");
    }
  }
}
