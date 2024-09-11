import { Controller } from "@hotwired/stimulus";
import $ from "jquery";
import "selectize/dist/js/selectize";

export default class extends Controller {
  static targets = ["button", "select", "form"];

  selectTargetConnected() {
    this.selectTarget.selectize.on("blur", () => this.hideForm());
  }

  showForm() {
    if ($(this.buttonTarget).is(":visible")) {
      $(this.buttonTarget).hide();
    }
    $(this.formTarget).show();
    this.selectTarget.selectize.focus();
  }

  hideForm() {
    $(this.buttonTarget).show();
    $(this.formTarget).hide();
  }
}
