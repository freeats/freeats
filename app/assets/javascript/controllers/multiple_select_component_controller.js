import SelectComponentController from "./select_component_controller";
import $ from "jquery";
import "selectize/dist/js/selectize";
import { arraysEqual, requestSubmitPolyfilled } from "../src/shared/input_utils";

export default class extends SelectComponentController {
  static targets = ["select"];

  static values = {
    buttonGroupSize: String,
    searchUrl: String,
    instantSubmit: Boolean,
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
      plugins: {
        deselect_options_via_dropdown: {},
        auto_position: {},
        dropdown_buttons: {
          buttonsClass: "btn btn-outline-primary",
          buttonGroupSize: this.buttonGroupSizeValue,
        },
        handle_disabled_options: {},
      },
      searchField: ["text", "value"],
      selectOnTab: false,
      showArrow: true,
      ...preloadedOptions,
      ...remoteSearchParams,
    });

    this.allowCheckmarkForDisabledOption(target.selectize);

    if (this.instantSubmitValue) this.#setupInstantSubmit(target);

    this.applyCommonFunctions(target, this.searchUrlValue);
  }

  selectTargetDisconnected(target) {
    this.destroySelectize(target);
  }

  parseOptions(text) {
    return JSON.parse(text);
  }

  #setupInstantSubmit(target) {
    let valuesOnOpen = [];

    target.selectize.on(
      "dropdown_open",
      () => valuesOnOpen = [...target.options].map((option) => option.value),
    );

    target.selectize.on(
      "dropdown_close",
      () => {
        let valuesOnClose = [...target.options].map((option) => option.value);

        if (!arraysEqual(valuesOnOpen, valuesOnClose)) {
          requestSubmitPolyfilled(target.form);
        }
      },
    );
  }
}
