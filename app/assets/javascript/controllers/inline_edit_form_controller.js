import { Controller } from "@hotwired/stimulus";
import $ from "jquery";
import { removeTooltips } from "../src/shared/tooltips";

export default class extends Controller {
  static targets = ["showView", "editView", "focusInput"];

  connect() {
    removeTooltips();
  }

  editViewTargetConnected(elem) {
    // addBack() is for case when the form itself is editViewTarget.
    $(elem).find("form").addBack().on("submit", () => {
      $(elem).find("[data-bs-toggle=tooltip]").tooltip("hide");
    });
  }

  show() {
    $(this.showViewTarget).hide();
    $(this.editViewTarget).show();
    // Focus and place cursor at the very end of the text.
    if (this.hasFocusInputTarget) {
      // Multiply by 2 to ensure the cursor always ends up at the end;
      // Opera sometimes sees a carriage return as 2 characters.
      const strLength = $(this.focusInputTarget).val().length * 2;

      $(this.focusInputTarget).focus();
      $(this.focusInputTarget)[0].setSelectionRange(strLength, strLength);
    }
  }

  hide() {
    $(this.showViewTarget).show();
    $(this.editViewTarget).hide();
  }
}
