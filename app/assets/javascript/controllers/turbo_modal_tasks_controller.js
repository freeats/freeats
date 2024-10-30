import { Controller } from "@hotwired/stimulus";
import $ from "jquery";
import { arraysEqual, requestSubmitPolyfilled } from "../src/shared/input_utils";
import { initBootstrapSelect } from "../src/shared/bootstrap_select";

export default class extends Controller {
  static targets = [
    "selectPickerWatchers",
    "selectAssignee",
    "selectpicker",
    "watchersForm",
    "defaultWatchers",
  ];

  static values = { currentMember: String, liveSearch: Boolean };

  connect() {
    this.modalListeners(document.getElementById("turbo_modal_window"));
    initBootstrapSelect();
  }

  modalListeners(modalWindow) {
    modalWindow.addEventListener("hide.bs.modal", () => {
      const newUrl = new URL(window.location.href);
      newUrl.pathname = newUrl.pathname.replace(/\/(new|\d+)$/, "");
      window.history.replaceState({}, null, newUrl);
    });

    if (!this.hasWatchersFormTarget) {
      const $selectWatchers = $(this.selectPickerWatchersTarget);
      const $selectAssignee = $(this.selectAssigneeTarget);
      const $defaultWatchers = $(this.defaultWatchersTarget);
      const currentMember = this.currentMemberValue;

      $selectAssignee.on("changed.bs.select", (e, clickedIndex, isSelected, previousValue) => {
        const assignee = $selectAssignee.val();
        let watchers = $selectWatchers.val();
        $selectWatchers.find("option[disabled]").removeAttr("disabled");

        if (assignee !== "") {
          $selectWatchers.find(`option[value=${assignee}]`).attr("disabled", "disabled");
          watchers.push(assignee);
        }

        const indexElement = watchers.indexOf(previousValue);

        if (currentMember === previousValue) {
          watchers.push(previousValue);
        } else if (indexElement !== -1) {
          watchers = watchers.splice(indexElement, 1);
        }

        watchers = [...new Set(watchers.concat($defaultWatchers.val().split(" ")))];
        $selectWatchers.selectpicker("val", watchers);
        $selectWatchers.selectpicker("refresh");
      });
    }
  }

  watchersFormTargetConnected() {
    const defaultWatchers = $(this.selectPickerWatchersTarget).val();
    $(this.watchersFormTarget).on("hide.bs.dropdown", function submitForm() {
      if (!arraysEqual(defaultWatchers, $(this).find("#task_watcher_ids").val())) {
        requestSubmitPolyfilled(this);
      }
    });
  }

  selectpickerTargetConnected(target) {
    $(target).selectpicker({
      liveSearch: !!target.dataset.liveSearch,
      style: "btn-outline-light selectpicker-button",
    });
  }
}
