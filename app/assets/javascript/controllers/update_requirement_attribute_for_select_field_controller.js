import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "mainField"];

  mainFieldTargetConnected() {
    this.setRequiredAttribute(this.mainFieldTarget.value);

    this.mainFieldTarget.addEventListener("change", (event) => {
      this.setRequiredAttribute(event.target.value);
    });
  }

  mainFieldTargetDisconnected() {
    this.mainFieldTarget.removeEventListener("change", (event) => {
      this.setRequiredAttribute(event.target.value);
    });
  }

  setRequiredAttribute(mainFieldValue) {
    let required = null;
    if (mainFieldValue === "") {
      required = false;
    } else {
      required = true;
    }

    this.formTarget.querySelectorAll("select").forEach((el) => {
      el.required = required;

      const { selectize } = el;
      if (selectize) {
        selectize.isRequired = required;

        if ((selectize.items.length === 0 && required) || !required) {
          selectize.$control_input.prop("required", required);
        }
      }
    });
  }
}
