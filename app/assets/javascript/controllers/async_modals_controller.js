import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  static targets = ["focusAfterShown"];

  connect() {
    const modal = new Modal(this.element);

    modal.show();
  }

  focusAfterShownTargetConnected(target) {
    this.element.addEventListener(
      "shown.bs.modal",
      () => target.focus(),
    );
  }

  complete() {
    // In some places, called by the turbo:submit-end event, `.hide()` within this function
    // fails to do all its "magic" and the modal appears again when you click back in the browser.
    // The following lines remove the dark background added by modal class
    // and styles from the `body` tag and the modal itself without animation.
    const { body } = document;

    body.removeAttribute("class");
    body.style.overflow = "";
    body.style.paddingRight = "";

    [document.getElementsByClassName("modal-backdrop")[0], this.element]
      .forEach((elem) => elem.remove());

    // This is to ensure that when the back button is pressed in the browser,
    // the cached turbo_frame will not async load the form content again from the src attribute.
    document.getElementById("turbo_modal_window")
      .removeAttribute("src");
  }
}
