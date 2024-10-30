// bootstrap-select requires `bootstrap` to be in global namespace to reference `Dropdown`.
import * as bootstrap from "bootstrap";

import $ from "jquery";

window.bootstrap = bootstrap;
require("bootstrap-select/js/bootstrap-select");

const DEFAULT_SELECTOR = "select.select-picker:not(.selectpicker-placeholder)";

function createSelectPickerPlaceholders() {
  // Bootstrap select takes a while to load, this puts placeholder selects on the page while the
  // real selects are still loading.
  $(DEFAULT_SELECTOR).each((id, element) => {
    const $outerDiv = $(element).parent();
    $outerDiv.clone().insertAfter($outerDiv).addClass("selectpicker-placeholder");
  });
}

export function preInitBootstrapSelect() {
  // https://github.com/snapappointments/bootstrap-select/issues/1413#issuecomment-231936277
  createSelectPickerPlaceholders();
  $(DEFAULT_SELECTOR).selectpicker("destroy").addClass("selectpicker");
}

export function initBootstrapSelect(selector = DEFAULT_SELECTOR) {
  const commonSelectPickerOptions = {
    liveSearch: true,
    actionsBox: true,
    dropupAuto: false,
    style: "btn-outline-light selectpicker-button",
    deselectAllText: "None",
    selectAllText: "All",
  };
  // Later reloaded on turbo:before-cache event to avoid duplicating itself.
  $(selector).selectpicker(commonSelectPickerOptions);
  $(selector).on("changed.bs.select", (e) => {
    if (!$(e.target).prop("multiple")) {
      $("div.dropdown-menu, .dropdown-toggle", $(e.target).parent()).removeClass("show");
    }
  });
  $(".selectpicker-placeholder").remove();
}
