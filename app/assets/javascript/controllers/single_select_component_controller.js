import SelectComponentController from "./select_component_controller";
import "selectize/dist/js/selectize";
import $ from "jquery";

export default class extends SelectComponentController {
  static targets = ["select"];

  static values = {
    searchUrl: String,
    allowEmptyOption: Boolean,
    dropdownParent: String,
    withChevron: Boolean,
  };

  selectTargetConnected(target) {
    // The preloaded options are used to set the initial state of the selectize instance.
    // We may need to restore the selectize instance's state after it's been destroyed,
    // such as when moving sections with select fields using the `sortable` library.
    let preloadedOptions = {};
    if (target.dataset.state) {
      preloadedOptions = JSON.parse(target.dataset.state);
      target.removeAttribute("data-state");
    }

    let remoteSearchParams = {};
    if (this.searchUrlValue !== "") {
      remoteSearchParams = this.searchParams(
        target,
        this.searchUrlValue,
        this.parseOptions,
      );
    }

    this.purgeDeadSelectize(target);

    $(target).selectize({
      plugins: ["auto_position"],
      allowEmptyOption: this.allowEmptyOptionValue,
      selectOnTab: false,
      searchField: ["text", "value"],
      showArrow: this.withChevronValue,
      dropdownParent: this.dropdownParentValue,
      ...preloadedOptions,
      ...remoteSearchParams,
    });

    this.allowCheckmarkForDisabledOption(target.selectize);

    // Add a $gray-600 color for the empty option (with no value).
    target.selectize.on("item_add", (value, item) => {
      if (value !== "") return;

      item[0].style = "color: #6c757d !important";
    });

    this.applyCommonFunctions(target, this.searchUrlValue);
  }

  selectTargetDisconnected(target) {
    this.destroySelectize(target);
  }

  parseOptions(text) {
    return JSON.parse(text);
  }
}
