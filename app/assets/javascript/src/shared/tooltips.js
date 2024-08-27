import $ from "jquery";

// Fixes the bug with weird tooltip's behavior
export function removeTooltips() {
  $(".tooltip")
    .hide()
    .remove();
}
