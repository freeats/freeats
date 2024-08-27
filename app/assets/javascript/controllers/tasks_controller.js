import { Controller } from "@hotwired/stimulus";
import $ from "jquery";

export default class extends Controller {
  static targets = ["changeStatusForm"];

  static values = { lazyLoadFormUrl: String };

  connect() {
    if (this.hasLazyLoadFormUrlValue) {
      $("#turbo_modal_window").attr("src", this.lazyLoadFormUrlValue);
    }
    this.activateSelectpicker($(this.element));
  }

  changeStatusFormTargetConnected(element) {
    $(element).on("submit", (event) => {
      const $form = $(event.target);

      $form.find(":input[type=checkbox].current").addClass("hidden");
      $form.find(":input[type=checkbox].changed").removeClass("hidden");
    });
  }

  // Method used fetchResponse to retrieve from the turbo response pathEnding,
  // we used it to update window path URL when we open any task modal.
  changePath(event) {
    if (!event.detail.success) return;

    event.detail.fetchResponse.responseText.then(
      (response) => {
        const pathEnding = $(response).find('input[name="path_ending"]').val();
        if (!(/\/(new|\d+)$/.test(window.location.pathname))) {
          const newUrl = new URL(window.location.href);
          newUrl.pathname = `${newUrl.pathname}/${pathEnding}`;
          window.history.replaceState({}, null, newUrl);
        }
      },
    );
  }

  activateSelectpicker($elem) {
    $elem.find(".selectpicker").selectpicker({
      liveSearch: true,
      style: "btn-outline-light selectpicker-button",
    });
  }
}
