import { Controller } from "@hotwired/stimulus";
import $ from "jquery";

export default class extends Controller {
  initialize() {
    $(document).on("click", ".notification-close", function closeNotification() {
      // Class d-flex is removed because it has display: flex !important; style
      // that overrides display: none from fadeOut;
      $(this).closest(".notification").removeClass("d-flex");
      $(this).closest(".notification").fadeOut(300);
    });
  }
}
