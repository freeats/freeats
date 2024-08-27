import { Controller } from "@hotwired/stimulus";
import $ from "jquery";

export default class extends Controller {
  static targets = ["toggleButton", "noteSection"];

  connect() {
    this.initCollapse();
  }

  disconnect() {
    $(this.noteSectionTarget).removeClass("show");
  }

  initCollapse() {
    const $toggleButton = $(this.toggleButtonTarget);
    const $noteSection = $(this.noteSectionTarget);

    $toggleButton.attr("data-bs-toggle", "collapse");
    $toggleButton.attr("data-bs-target", `.${$noteSection.attr("class").split(" ")[1]}`);
    $noteSection.addClass("collapse");

    $toggleButton.attr("aria-expanded", "false");
  }
}
