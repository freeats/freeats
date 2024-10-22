import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["disqualifyButtonHiddenContainer"];

  onDisqualifyDropdownToggle() {
    this.disqualifyButtonHiddenContainerTarget.classList.toggle("card-hidden-container");
  }
}
