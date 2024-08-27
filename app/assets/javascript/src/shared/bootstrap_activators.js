import $ from "jquery";
import { Tooltip } from "bootstrap";
import { removeTooltips } from "./tooltips";

$(document).on(
  "turbo:load",
  () => new Tooltip("body", { selector: '[data-bs-toggle="tooltip"]', trigger: "hover" }),
);

[
  "turbo:click",
  "turbo:submit-start",
  "turbo:frame-render",
].forEach((eventName) => document.addEventListener(eventName, () => removeTooltips()));
