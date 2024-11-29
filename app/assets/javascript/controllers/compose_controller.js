import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "formBccInput",
    "formCcInput",
    "formSubject",
    "formBody",
    "newThreadForm",
  ];

  static outlets = [
    "button-utils",
  ];

  static values = { unsavedChangesWarning: String, tooltipOnOpenedComposeForm: String };

  newThreadFormTargetConnected() {
    this.#setupComposeInterruptHandler();
    this.initialSubjectContent = this.formSubjectTarget.value;
    this.buttonUtilsOutlets.forEach((btn) =>
      btn.disableWithTooltip(this.tooltipOnOpenedComposeFormValue),
    );
  }

  closeForm(event) {
    if (
      !event.target.dataset.ignoreInterruptWarning &&
      this.#hasUnsavedChanges() &&
      !window.confirm(this.unsavedChangesWarningValue)
    ) {
      event.preventDefault();
      return;
    }

    this.newThreadFormTarget.remove();
    this.buttonUtilsOutlets.forEach((btn) => btn.enableAndDisposeTooltip());

    window.onbeforeunload = null;
  }

  toggleAddressField(event) {
    const parent = event.target.parentElement;
    event.target.remove();

    if (parent.children.length === 0) parent.remove();

    const { targetName } = event.target.dataset;
    const targetElement = this[`${targetName}Target`];

    if (targetElement) {
      targetElement.classList.remove("d-none");
      const inputElement = targetElement.querySelector("input");

      if (inputElement) {
        inputElement.focus();
      }
    }
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this.#composeInterruptHandler);
    window.removeEventListener("beforeunload", this.#beforeunloadHandler);
  }

  #setupComposeInterruptHandler() {
    document.addEventListener("turbo:before-visit", this.#composeInterruptHandler);
    window.addEventListener("beforeunload", this.#beforeunloadHandler);
  }

  #beforeunloadHandler = (event) => {
    if (this.#hasUnsavedChanges()) {
      event.preventDefault();

      event.returnValue = "";
    }
  };

  #composeInterruptHandler = (event) => {
    if (
      this.#hasUnsavedChanges() &&
      !window.confirm(this.unsavedChangesWarningValue)
    ) {
      event.preventDefault();
      event.returnValue = "";
    }
  };

  #hasUnsavedChanges() {
    if (!this.hasFormSubjectTarget || !this.hasFormBodyTarget) return false;

    const subjectValue = this.formSubjectTarget.value;
    const bodyValue = this.formBodyTarget.value;
    return subjectValue !== this.initialSubjectContent ||
      (!!bodyValue && bodyValue !== "");
  }
}
