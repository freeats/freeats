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

$(document).on(
  "turbo:load",
  () => {
    const setupFormValidation = () => {
      // Select the form that requires validation
      const form = document.querySelector("#form-with-recaptcha.needs-validation");
      if (form) {
        // Initialize Bootstrap tooltips on page load
        new Tooltip("body", {
          selector: '[data-bs-toggle="tooltip"]',
          trigger: "hover",
        });
        // Disable default HTML5 validation
        // This is not done in the view,
        // since the form must be validated using HTML5
        // if JS is disabled in the browser.
        form.setAttribute("novalidate", "true");

        form.addEventListener("submit", function (event) {
          if (!form.checkValidity()) {
            // If the form is invalid, prevent submission.
            event.preventDefault();
            event.stopPropagation();
          }
          // Add a class to visually indicate the form has been validated.
          form.classList.add("was-validated");
        }, false);
      }
    };

    setupFormValidation();
  },
);
