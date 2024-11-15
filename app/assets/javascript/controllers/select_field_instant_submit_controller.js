import { Controller } from "@hotwired/stimulus";
import { requestSubmitPolyfilled } from "../src/shared/input_utils";

export default class extends Controller {
  static targets = ["selectField"];

  selectFieldTargetConnected(target) {
    const form = target.closest("form");
    const selectize = target.selectize;

    // Used explicitly `requestSubmitPolyfilled` because `turbo-instant-submit`
    // works incorrectly when we type something irrelevant and lose focus.
    selectize.on("change", () => {
      // Turn off focus to prevent reopening the selectize dropdown after turbo action.
      selectize.$control_input.blur();
      requestSubmitPolyfilled(form);
    });
  }
}
