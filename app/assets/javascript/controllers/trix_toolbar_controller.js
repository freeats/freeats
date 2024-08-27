import { Controller } from "@hotwired/stimulus";
import $ from "jquery";

export default class extends Controller {
  static targets = [
    "button",
    "linkbar",
    "linkButton",
    "unlinkButton",
    "linkInput",
    "linkbarButton",
  ];

  connect() {
    this.editor = $(this.element).find("trix-editor")[0].editor;
  }

  link() {
    const url = this.linkInputTarget.value;
    this.editor.activateAttribute("href", url);
    this.toggleLinkbar();
    this.update();
  }

  unlink() {
    this.editor.deactivateAttribute("href");
    this.update();
  }

  toggleLinkbar() {
    const newDisplay = this.linkbarTarget.style.display === "none" ? "block" : "none";
    this.linkbarTarget.style.display = newDisplay;
  }

  update() {
    if (this.hasLinkbarButtonTarget) {
      const hrefActive = this.editor.composition.currentAttributes.href;
      if (hrefActive) {
        this.linkButtonTarget.style.display = "none";
        this.unlinkButtonTarget.style.display = null;
        this.linkbarButtonTarget.classList.add("active-trix-button");
        this.linkInputTarget.value = hrefActive;
      } else {
        this.linkButtonTarget.style.display = null;
        this.unlinkButtonTarget.style.display = "none";
        this.linkbarButtonTarget.classList.remove("active-trix-button");
      }
    }
    this.buttonTargets.forEach((button) => {
      const attribute = button.dataset.trixAttribute;
      if (this.editor.composition.currentAttributes[attribute]) {
        button.classList.add("active-trix-button");
      } else {
        button.classList.remove("active-trix-button");
      }
    });
  }
}
