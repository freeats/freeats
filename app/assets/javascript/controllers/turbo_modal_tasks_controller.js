import { Controller } from "@hotwired/stimulus";
import { initBootstrapSelect } from "../src/shared/bootstrap_select";

export default class extends Controller {
  static targets = [
    "selectWatchersInNewTask",
    "selectAssigneeInNewTask",
  ];

  static values = { currentMember: String, liveSearch: Boolean, defaultWatchers: Array };

  connect() {
    document.getElementById("turbo_modal_window").addEventListener("hide.bs.modal", () => {
      const newUrl = new URL(window.location.href);
      newUrl.pathname = newUrl.pathname.replace(/\/(new|\d+)$/, "");
      window.history.replaceState({}, null, newUrl);
    });
    initBootstrapSelect();
  }

  selectAssigneeInNewTaskTargetConnected(target) {
    let previousAssignee = target.selectize.items[0];

    target.selectize.on("change", (assignee) => {
      const watchersSelectize = this.selectWatchersInNewTaskTarget.selectize;

      let watchers = watchersSelectize.items;
      const indexElement = watchers.indexOf(previousAssignee);
      if (this.currentMemberValue === previousAssignee) {
        watchers.push(previousAssignee);
      } else if (indexElement !== -1) {
        watchers.splice(indexElement, 1);
      }

      if (previousAssignee) watchersSelectize.options[previousAssignee].disabled = false;
      if (assignee) {
        watchersSelectize.options[assignee].disabled = true;
        watchers.push(assignee);
      }

      watchers = [...new Set(watchers.concat(this.defaultWatchersValue))];

      watchersSelectize.clearCache();
      watchersSelectize.refreshOptions(false);

      watchersSelectize.clear({ silent: true });
      watchersSelectize.addItems(watchers);

      watchersSelectize.close();

      previousAssignee = assignee;
    });
  }
}
