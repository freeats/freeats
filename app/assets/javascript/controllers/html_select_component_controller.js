import SelectComponentController from "./select_component_controller";
import $ from "jquery";
import "selectize/dist/js/selectize";
import { disableQuickSearchListeners, enableQuickSearchListeners } from "../src/lib/quick_search";

export default class extends SelectComponentController {
  static targets = ["select"];

  static values = {
    searchUrl: String,
    options: String,
    itemAsRichText: Boolean,
    type: String,
    dropdownParent: String,
  };

  selectTargetConnected(target) {
    // The preloaded options are used to set the initial state of the selectize instance.
    // We may need to restore the selectize instance's state after it's been destroyed,
    // such as when moving sections with select fields using the `sortable` library.
    // Also we may have preloaded options for exactly this select field
    // because the Rails select helpers can`t work correclty with rich text in the options,
    // and we have to pass them as a stimulus controller value.
    let preloadedOptions = {};
    if (target.dataset.state) {
      preloadedOptions = JSON.parse(target.dataset.state);
      target.removeAttribute("data-state");
    } else if (this.optionsValue !== "") {
      const parsedOptions = this.parseOptions(this.optionsValue);
      preloadedOptions = {
        options: parsedOptions,
        items: this.selectedOptions(parsedOptions),
      };
    }

    let remoteSearchParams = {};
    if (this.searchUrlValue !== "") {
      remoteSearchParams = this.searchParams(
        target,
        this.searchUrlValue,
        this.parseOptions,
        this.typeValue,
      );
    }

    // Allow to render the selected option as rich text or as plain text.
    const renderItem = this.itemAsRichTextValue ? "html" : "label";

    this.purgeDeadSelectize(target);

    $(target).selectize({
      plugins: ["auto_position"],
      showArrow: false, // Hide the default down arrow to replace it with our own.
      selectOnTab: false,
      searchField: "html",
      dropdownParent: this.dropdownParentValue,
      ...preloadedOptions,
      ...remoteSearchParams,
      ...this.quickSearchParams(this.typeValue),
      render: {
        option: (data) => `<div class="option">${data.html}</div>`,
        item: (data) => `<div class="item">${data[renderItem]}</div>`,
        // Hide the optgroup header, used for the quick search.
        optgroup_header: () => "<div></div>",
      },
    });

    if (this.typeValue === "quick_search") {
      enableQuickSearchListeners(document, target.selectize);
    }

    this.applyCommonFunctions(target, this.searchUrlValue);
  }

  selectTargetDisconnected(target) {
    this.destroySelectize(target);

    if (this.typeValue === "quick_search") {
      disableQuickSearchListeners(document);
    }
  }

  parseOptions(text) {
    const options = [];
    const parser = new DOMParser();
    const doc = parser.parseFromString(text, "text/html");

    doc.querySelectorAll("option").forEach((option) => {
      const attributes = Object.values(option.attributes).reduce(
        (acc, attr) => {
          acc[attr.name] = attr.value;
          return acc;
        },
        {},
      );

      options.push({ html: option.innerHTML, ...attributes });
    });

    return options;
  }

  selectedOptions(options) {
    return options.reduce((acc, option) => {
      if (option.selected) acc.push(option.value);
      return acc;
    }, []);
  }

  quickSearchParams(type) {
    if (type !== "quick_search") return {};

    return {
      optgroups: [
        { value: "candidate" },
        { value: "lead" },
        { value: "position" },
        { value: "company" },
      ],
      lockOptgroupOrder: true,
    };
  }
}
