import { Controller } from "@hotwired/stimulus";
import $ from "jquery";
import "selectize/dist/js/selectize";

export default class extends Controller {
  static targets = ["button", "input", "form"];

  static values = { searchUrl: String };

  connect() {
    if (this.hasInputTarget) {
      $(this.inputTarget).selectize({
        maxItems: 1,
        create: false,
        selectOnTab: true,
        render: {
          option: (data) => data.html,
          item: (data, escape) => `<div>${escape(data.text)}</div>`,
        },
      });
    }
    this.inputTarget.selectize.on("blur", () => this.hideForm());
    this.inputTarget.selectize.on(
      "change",
      () => $(this.formTarget).find("[type=submit]").trigger("click"),
    );
  }

  showForm() {
    if ($(this.buttonTarget).is(":visible")) {
      $(this.buttonTarget).hide();
    }
    $(this.formTarget).show();
    // Possible optimization: don't fetch members every time the form gets re-rendered. Instead,
    // store the data and use it for the re-rendered form.
    fetch(this.searchUrlValue)
      .then((response) => response.json())
      .then((data) => {
        Object.entries(data).forEach((option) => this.inputTarget.selectize.addOption(option));
        this.inputTarget.selectize.open();
        this.inputTarget.selectize.focus();
      });
  }

  hideForm() {
    $(this.buttonTarget).show();
    $(this.formTarget).hide();
  }

  disconnect() {
    // Avoid multiple application of `selectize`.
    if (this.hasInputTarget) {
      this.inputTarget.selectize.destroy();
    }
  }
}
