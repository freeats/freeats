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
      showArrow: this.withChevronValue,
      ...preloadedOptions,
      ...remoteSearchParams,
    });

    this.allowCheckmarkForDisabledOption(target.selectize);

    if (this.instantSubmitValue) this.#setupInstantSubmit(target);

    this.#truncateItemsAddlisteners(target.selectize);

    this.applyCommonFunctions(target, this.searchUrlValue);
  }

  selectTargetDisconnected(target) {
    this.destroySelectize(target);

    window.removeEventListener("resize", () => {
      this.#truncateItems(target.selectize);
    });
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

  #truncateItemsAddlisteners(selectize) {
    this.#truncateItems(selectize);

    selectize.on("change", () => {
      this.#truncateItems(selectize);
    });

    window.addEventListener("resize", () => {
      this.#truncateItems(selectize);
    });
  }

  #truncateItems(selectize) {
    const $selectizeInput = selectize.$control;
    const inputWidth = $selectizeInput[0].clientWidth -
      parseFloat($selectizeInput.css("padding-left")) -
      parseFloat($selectizeInput.css("padding-right"));

    const [firstItem, ...otherItems] = $selectizeInput.find(".item");

    if (!firstItem) return;

    const firstItemWidth = firstItem.clientWidth;

    if (inputWidth <= firstItemWidth) {
      $selectizeInput.css("text-overflow", "");
      otherItems.forEach((item) => item.style.visibility = "hidden");
    } else if (selectize.items.length > 1) {
      $selectizeInput.css("text-overflow", "ellipsis");
      [firstItem, ...otherItems].forEach((item) => item.style.visibility = "");
    } else {
      $selectizeInput.css("text-overflow", "");
      [firstItem, ...otherItems].forEach((item) => item.style.visibility = "");
    }
  }
}
