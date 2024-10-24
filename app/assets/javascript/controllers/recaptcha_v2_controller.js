import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {

  static targets = ["form"];

  connect() {
    const modal = new Modal(this.element, {});

    modal.show();

    window.recaptchaSubmit = function recaptchaSubmit() {
      const form = this.formTarget;

      form.setAttribute("verified", "true");
      Turbo.navigator.submitForm(form);
    };
  }
}
