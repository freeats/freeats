import { Controller } from "@hotwired/stimulus";
import $ from "jquery";

export default class extends Controller {
  static targets = [
    "collapsedNotes",
    "collapseButton",
    "replyTab",
    "collapsedStateIcon"
  ];

  showReplyTab(e) {
    e.preventDefault();
    const $replyTab = $(this.replyTabTarget);

    $replyTab.addClass("active");

    if (this.hasCollapsedNotesTarget && !$(this.collapsedNotesTarget).hasClass("show")) {
      $(this.collapsedNotesTarget).collapse("show");
      $(this.collapsedStateIconTargets).toggle();
    }
    if (this.hasCollapseButtonTarget) {
      $(this.collapseButtonTarget).css({ position: "absolute", bottom: "3px" });
    }

    const $textarea = $replyTab.find("textarea:first");
    $textarea.focus();
  }

  cancelReply(e) {
    e.preventDefault();
    if (!this.hasCollapsedNotesTarget) {
      $(this.replyTabTarget).removeClass("active");
    } else {
      this.collapseButtonTarget.setAttribute("style", "");
      $(this.collapsedNotesTarget).collapse("hide");
      $(this.collapsedStateIconTargets).toggle();
    }
  }
}
