import { Controller } from "@hotwired/stimulus";
import $ from "jquery";

export default class extends Controller {
  static targets = ["column", "entityCard", "scrollColumnWrapper", "dropdownPlaceholder"];

  loadMore() {
    const threshold = 300; // Height of approximately 4 placement cards in px.
    const cardLimit = this.data.get("cardLimit");
    const currentCardCount = this.entityCardTargets.length;
    const scrollWindow = this.scrollColumnWrapperTarget;
    if (
      scrollWindow.scrollHeight - scrollWindow.clientHeight - scrollWindow.scrollTop > threshold
    ) {
      return;
    }

    switch (this.data.get("status")) {
      case "noMore":
        return;
      case "processing":
        return;
      case "failed":
        console.warn("pipeline-column#loadMore failed");
        return;
      case "probablyMore": {
        this.data.set("status", "processing");
        const url = new URL(window.location.origin + this.data.get("endpoint"));
        const currentParams = new URLSearchParams(window.location.search);
        const searchParams = new URLSearchParams();
        searchParams.set("limit", cardLimit);
        searchParams.set("offset", currentCardCount);
        searchParams.set("stage", this.data.get("stage"));
        searchParams.set("pipeline_tab", currentParams.get("pipeline_tab"));
        url.search = searchParams.toString();

        fetch(url)
          .then((response) => {
            if (response.ok) return response.text();
            throw new Error(`${response.url}: ${response.statusText}`);
          })
          .then((html) => {
            if (!html.trim().length) {
              this.data.set("status", "noMore");
              return;
            }
            const $html = $(html);
            $(this.columnTarget).append($html);
            this.data.set("status", "probablyMore");
          })
          .catch((e) => {
            console.error(e);
            this.data.set("status", "failed");
          });
        break;
      }
    }
  }

  async mobileStageDropdownPlaceholder(event) {
    $(this.dropdownPlaceholderTarget).html($(event.delegateTarget).html());
  }
}
