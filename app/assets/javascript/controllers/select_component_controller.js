import { Controller } from "@hotwired/stimulus";

const deferredKeysPrefix = "deferredSelectize";
const dataNameforDeferredKeys = "deferredKeysToRestore";

// This controller is used as a parent for other select controllers.
export default class SelectComponentController extends Controller {
  searchParams(target, url, parseFunction, type) {
    return {
      score: () => () => 1, // Restrict ordering results. Order them in the backend.
      load: this.#remoteSearch(target, url, parseFunction, type),
      loadThrottle: 300,
    };
  }

  // Allow to show the checkmark for disabled options if the option is selected.
  allowCheckmarkForDisabledOption(selectize) {
    // Patch the selectize method to get the option even if it is disabled.
    selectize.getOption = (value) =>
      selectize.getElementWithValue(
        value,
        selectize.$dropdown_content.find(".option"),
      );
  }

  destroySelectize({ selectize, dataset }) {
    let state = null;
    // In case if we already destroyed the selectize instance.
    // It could happen in the `array_fields_controller.js`.
    if (selectize) {
      state = {
        options: Object.values(selectize.options),
        items: selectize.items,
      };
    }
    if (selectize) selectize.destroy();

    // Save the state of the selectize instance to restore it later.
    // It could happen in the `array_fields_controller.js`
    // when we move the select field to another place in DOM.
    if (state) dataset.state = JSON.stringify(state);

    // Restore the deferred data keys.
    if (dataset[dataNameforDeferredKeys]) {
      dataset[dataNameforDeferredKeys].split(",").forEach((key) => {
        const newKey = deferredKeysPrefix + key.charAt(0).toUpperCase() +
          key.slice(1);
        dataset[newKey] = dataset[key];
        delete dataset[key];
      });
      delete dataset[dataNameforDeferredKeys];
    }
  }

  // The popstate action may restore the selectize elements in the DOM.
  // We have to remove them to prevent doubling the select field.
  purgeDeadSelectize(target) {
    const elementToRemove = target.parentElement.querySelector(
      ".selectize-control",
    );
    if (elementToRemove) elementToRemove.remove();
  }

  applyCommonFunctions(target, searchUrlValue) {
    const selectize = target.selectize;

    if (searchUrlValue !== "") this.#allowToReSearch(selectize);
    if (target.attributes.readonly) this.#lock(target);
    if (selectize.isRequired) this.#restrictEnterKeyIfNoneSelected(target);
    this.#expandDropdownOnPressingEnter(selectize);
    this.#applyDeferredData(target.dataset);
  }

  // Private functions.

  #remoteSearch(target, url, parseFunction, type) {
    const cleanOptions = this.#cleanOptions;
    const request = this.#request;

    return function query(q, cb) {
      if (q.trim().length < 3) {
        cb([]);
        return;
      }

      cleanOptions(target.selectize);

      let finalUrl = url.replace("QUERY", encodeURIComponent(q));
      if (type) finalUrl += `&type=${type}`;

      if (type === "quick_search") {
        ["candidate", "position"].forEach((category) => {
          request(`${finalUrl}&searching_for=${category}`, cb, parseFunction);
        });
      } else {
        request(finalUrl, cb, parseFunction);
      }
    };
  }

  #request(url, cb, parseFunction) {
    fetch(url)
      .then((response) => {
        if (response.ok) return response.text();
        throw new Error(`${response.url}: ${response.statusText}`);
      })
      .then((text) => {
        cb(parseFunction(text));
      })
      .catch((e) => {
        console.error(e);
        cb([]);
      });
  }

  // Remove old not selected options.
  #cleanOptions(selectize) {
    Object.values(selectize.options)
      .forEach((option) => {
        const value = option.value.toString();
        if (!selectize.items.includes(value)) selectize.removeOption(value);
      });
  }

  // Clear loaded search values, allow to load them again when the user edits
  // the search field several times without changing the focus.
  #allowToReSearch(selectize) {
    selectize.on("type", () => {
      selectize.loadedSearches = {};
    });
  }

  // Simulate the readonly attribute.
  #lock(target) {
    target.selectize.lock();
    target.selectize.$control_input.attr("readonly", true);
  }

  // Prevent form submission when the input is empty.
  // It may happen when we type something irrelevant and press enter.
  #restrictEnterKeyIfNoneSelected(target) {
    target.form.onkeydown = (e) => {
      if (e.key === "Enter" && target.selectize.items.length === 0) {
        e.preventDefault();
        return false;
      }

      return true;
    };
  }

  #expandDropdownOnPressingEnter(selectize) {
    var original = selectize.onKeyDown;

    // Patched `onKeyDown` function.
    selectize.onKeyDown = (function () {
      return function (e) {
        if (e.key === "Enter" && !selectize.isOpen) selectize.open();

        return original.apply(this, arguments);
      };
    })();
  }

  // Apply deferred data to the selectize instance.
  // Solves the problem when data attributes are applied to the original select field,
  // and the stimulus controller related to these attributes invokes several times instead of once.
  #applyDeferredData(dataset) {
    Object.keys(dataset).forEach((key) => {
      if (key.includes(deferredKeysPrefix)) {
        let newKey = key.replace(deferredKeysPrefix, "");
        newKey = newKey.charAt(0).toLowerCase() + newKey.slice(1);
        dataset[newKey] = dataset[key];
        delete dataset[key];

        // These keys should be restored after destroying the selectize instance.
        if (dataset[dataNameforDeferredKeys]) {
          dataset[dataNameforDeferredKeys] = dataset[dataNameforDeferredKeys] +
            "," + newKey;
        } else dataset[dataNameforDeferredKeys] = newKey;
      }
    });
  }
}
