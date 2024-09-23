import $ from "jquery";
import { Turbo } from "@hotwired/turbo-rails";

export function enableQuickSearchListeners(document, selectize) {
  $(document).on("keydown.focusSearchField", (event) => {
    // Do not focus the quick search field if it is aluready focused.
    if ($(event.target).is(":focus")) {
      return true;
    }

    // Focus the quick search field when the user presses the 's' key.
    if (event.keyCode === 83) {
      selectize.focus();
      return false;
    }

    return true;
  });

  // Redirect to the link when an option is selected.
  selectize.on("item_add", function goToLink(_value, item) {
    // Clear options so that the selected item does not show up in the quick search field.
    this.clear();
    Turbo.visit(item[0].querySelector("a").href);
  });
}

export function disableQuickSearchListeners(document) {
  $(document).off("keydown.focusSearchField");
}
