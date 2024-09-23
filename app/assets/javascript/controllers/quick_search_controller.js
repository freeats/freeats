import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static visibleInput;

  initialize() {
    const [visibleInput] = this.element.selectize.$control_input;

    this.visibleInput = visibleInput;
  }

  connect() {
    this.changePlaceholder();
  }

  changePlaceholder() {
    // < 992px == < lg default bootstrap breakpoint
    if (window.innerWidth < 992) {
      this.visibleInput.placeholder = "Search";
    } else {
      this.visibleInput.placeholder = "Press S to search";
    }
  }
}
