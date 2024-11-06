import SelectComponentController from "./select_component_controller";
import TomSelect from "tom-select/dist/js/tom-select.complete.js";
import $ from "jquery";

export default class extends SelectComponentController {
  static targets = ["select"];

  static values = {
    searchUrl: String,
    allowEmptyOption: Boolean,
    dropdownParent: String,
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

    // this.purgeDeadSelectize(target);

    new TomSelect(target, {
      // plugins: ["auto_position"], do not exist
      allowEmptyOption: this.allowEmptyOptionValue,
      selectOnTab: false,
      searchField: ["text", "value"],
      // showArrow: true, do not exist
      dropdownParent: this.dropdownParentValue,
      ...preloadedOptions,
      ...remoteSearchParams, // did not work remote search
    });

    // this.allowCheckmarkForDisabledOption(target.selectize);

    // Add a $gray-600 color for the empty option (with no value).
    // target.selectize.on("item_add", (value, item) => {
    //   if (value !== "") return;

    //   item[0].style = "color: #6c757d !important";
    // });

    // this.applyCommonFunctions(target, this.searchUrlValue);
  }

  selectTargetDisconnected(target) {
    this.destroySelectize(target);
  }

  parseOptions(text) {
    return JSON.parse(text);
  }
}
