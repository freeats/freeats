import $ from "jquery";
import { Tooltip } from "bootstrap";
import { removeTooltips } from "./tooltips";

$(document).on(
  "turbo:load",
  () => new Tooltip("body", { selector: '[data-bs-toggle="tooltip"]', trigger: "hover" }),
);

$(document).on("click", ".toggle-chevron-content", function toggleIcons() {
  $(this).find(".icon-chevron-hide, .icon-chevron-show").toggle();
});

[
  "turbo:click",
  "turbo:submit-start",
  "turbo:frame-render",
].forEach((eventName) => document.addEventListener(eventName, () => removeTooltips()));
