import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "formToSelect",
    "formBccInput",
    "formCcInput",
    "formSubject",
    "formBody",
    "newThreadForm",
  ];

  static outlets = [
    "button-utils",
  ];

  newThreadFormTargetConnected() {
    this.#setupComposeInterruptHandler();
    this.initialSubjectContent = this.formSubjectTarget.value;
    this.buttonUtilsOutlets.forEach((btn) =>
      // Use locale!!!!!!
      btn.disableWithTooltip(
        "Please make sure you send the previous email before opening a new one",
      ),
    );
  }


  formToSelectTargetConnected() {
    this.#findInputToFocus.focus();
  }

  closeForm(event) {
    if (
      !event.target.dataset.ignoreInterruptWarning &&
      this.#hasUnsavedChanges() &&
      // Use locale!!!!!!
      !window.confirm(
        "You have unsaved changes. If you leave this page, you will lose those changes.",
      )
    ) return;

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

  get #findInputToFocus() {
    if (this.formToSelectTarget.value === "") {
      return this.formToSelectTarget.selectize;
    }

    const subjectInput = this.formSubjectTarget;
    if (subjectInput.value === "") {
      return subjectInput;
    }
    return this.formBodyTarget;
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
      // Use locale!!!!!!
      !window.confirm(
        "You have unsaved changes. If you leave this page, you will lose those changes.",
      )
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
