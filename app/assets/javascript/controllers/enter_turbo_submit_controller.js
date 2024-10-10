import { Controller } from "@hotwired/stimulus";
import { requestSubmitPolyfilled } from "../src/shared/input_utils";

export default class extends Controller {
  static targets = ["shortcut"];

  connect() {
    this.element.addEventListener("keydown", (event) => {
      // Don't prevent default 'enter' behaviour for trix-editor/textarea elements.
      const isRichText = /(trix-editor|textarea)/.test(
        event.target.tagName.toLowerCase(),
      );

      if (event.code === "Enter" && !isRichText) {
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
