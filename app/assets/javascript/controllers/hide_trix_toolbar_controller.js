import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.element.querySelectorAll("trix-toolbar").forEach((toolbar) => {
      toolbar.remove();
    });
  }
}
