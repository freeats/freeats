import { Controller } from "@hotwired/stimulus";
import $ from "jquery";

export default class extends Controller {
  static targets = ["button", "select", "form"];

  selectTargetConnected() {
    this.selectTarget.selectize.on("blur", () => this.hideForm());
  }

  showForm() {
    if ($(this.buttonTarget).is(":visible")) {
      this.buttonTarget.classList.add("d-none");
    }
    $(this.formTarget).show();
    this.selectTarget.selectize.focus();
  }

  hideForm() {
    this.buttonTarget.classList.remove("d-none");
    $(this.formTarget).hide();
  }
}
