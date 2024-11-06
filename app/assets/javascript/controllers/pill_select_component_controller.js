import SelectComponentController from "./select_component_controller";
import $ from "jquery";
import "selectize/dist/js/selectize";
import TomSelect from "tom-select/dist/js/tom-select.complete.js";

export default class extends SelectComponentController {
  static targets = ["select"];

  static values = { searchUrl: String, createNewOption: Boolean };

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

    // const plugins = ["auto_position"]; did not exist
    const plugins = [];
    // Do not show the remove button if the select field is readonly or disabled.
    const { attributes } = target;
    if (!attributes.readonly && !attributes.disabled) {
      plugins.push("remove_button");
    }

    this.purgeDeadSelectize(target);

    new TomSelect(target, {
      plugins,
      selectOnTab: false,
      create: this.createNewOptionValue,
      createOnBlur: this.createNewOptionValue,
      // showArrow: true, did not exist
      ...preloadedOptions,
      ...remoteSearchParams,
    });

    // this.applyCommonFunctions(target, this.searchUrlValue);
  }

  selectTargetDisconnected(target) {
    this.destroySelectize(target);
  }

  parseOptions(text) {
    return JSON.parse(text);
  }
}
