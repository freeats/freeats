import { Application } from "@hotwired/stimulus";

// eslint-disable-next-line import/no-unresolved, import/extensions
import controllers from "./**/*_controller.js";

window.Stimulus = Application.start();

controllers.forEach((controller) => {
  window.Stimulus.register(controller.name, controller.module.default);
});

window.Stimulus.debug = process.env.NODE_ENV === "development";
