import { Controller } from "@hotwired/stimulus";
import { Tooltip } from "bootstrap";

export default class extends Controller {
  disableWithTooltip(tooltip) {
    const { parentElement } = this.element;
    Tooltip.getOrCreateInstance(parentElement, { title: tooltip });

    this.element.classList.add("disabled");
    this.element.setAttribute("disabled", true);
  }

  enableAndDisposeTooltip() {
    const { parentElement } = this.element;
    const tooltip = Tooltip.getInstance(parentElement);

    tooltip.dispose();
    this.element.classList.remove("disabled");
    this.element.removeAttribute("disabled");
  }
}
