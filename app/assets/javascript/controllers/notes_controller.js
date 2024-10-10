import { Controller } from "@hotwired/stimulus";
import $ from "jquery";
import Tribute from "tributejs";
import { clearFormDraft, retrieveFormDraft, storeFormDraft } from "../src/ats/draft_storage";

export default class extends Controller {
  static targets = [
    "threads",
    "noteTextArea",
    "noteForm",
  ];

  connect() {
    this.addClickOnDropdownItemListener();
    this.addClickOnCollapseButtonListeners();
    this.attachTribute();
    $(".note-form").each(function fillNoteFormsFromDrafts() {
      retrieveFormDraft(this);
    });
    this.handleLinkToNote();
  }

  storeNoteForm(e) {
    storeFormDraft(e.currentTarget);
  }

  clearNoteForm(e) {
    if (!e.detail.success) return;

    this.noteTextAreaTarget.value = "";
    clearFormDraft(e.currentTarget);
  }

  resetNoteForm() {
    clearFormDraft(this.noteFormTarget);
    $(this.noteFormTarget).trigger("reset");
  }

  addClickOnDropdownItemListener() {
    $(this.threadsTargets).on("click", ".dropdown-item", function toggleDropdown() {
      $(this).closest(".dropdown-menu").prev("button").dropdown("hide");
    });
  }

  addClickOnCollapseButtonListeners() {
    $(this.threadsTargets).on(
      "hide.bs.collapse",
      ".collapse",
      function addCollapseButtonListener() {
        const $noteThread = $(this).closest(".note-thread");
        const $collapseButton = $noteThread.find(".thread-collapse-button");
        const firstNoteId = $noteThread.find(".note:first").prop("id").split("-").pop();
        if ($noteThread.find(`#note-edit-${firstNoteId}.active`).length) {
          $collapseButton.css({ position: "absolute", bottom: "2px" });
        } else {
          $collapseButton.css({ position: "static" });
        }
      },
    );
    $(this.threadsTargets).on(
      "show.bs.collapse",
      ".collapse",
      function addCollapseButtonListener() {
        const $noteThread = $(this).closest(".note-thread");
        const $collapseButton = $noteThread.find(".thread-collapse-button");
        const $lastNote = $noteThread.find(".note:last");

        if (!$lastNote.find(".note-thread-reply.active").length) {
          const noteThreadId = $noteThread.prop("id").split("_").pop();
          const $replyTab = $(`#note-thread-reply-${noteThreadId}`);
          $replyTab.addClass("active");
          $noteThread.find(".note-show").addClass("active");
          $noteThread.find(".note-edit").removeClass("active");
          $replyTab.addClass("active");
        }
        $collapseButton.css({ position: "absolute", bottom: "2px" });
      },
    );
    $(this.threadsTargets).on("shown.bs.collapse", ".collapse", function scrollToLastNote() {
      const $noteThread = $(this).closest(".note-thread");
      const $lastNote = $noteThread.find(".note:last");

      if ($lastNote.find(".note-thread-reply.active textarea:focus").length) {
        const scrollOffset = $lastNote.offset().top - $("nav.navbar.header").innerHeight();
        $(window).scrollTop(scrollOffset);
      }
    });
  }

  attachTribute() {
    const $noteTextArea = $(this.noteTextAreaTarget);
    this.modelId = $noteTextArea.data("model-id");

    if (this.modelId === undefined) {
      this.modelId = $noteTextArea
        .parents("#notes")
        .parent()
        .find(".new-note-area")
        .data("model-id");
    }

    const autocompletionRecruiterArray = Array.from(
      $(`#recruiter-mention-autocomplete-${this.modelId} li`),
    ).map((e) => ({ key: e.textContent, value: e.textContent }));

    const tribute = new Tribute({
      allowSpaces: true,
      values: autocompletionRecruiterArray,
      menuItemLimit: 4,
    });

    tribute.attach($noteTextArea);
  }

  handleLinkToNote() {
    const linkedNoteDomId = window.location.hash;
    if (linkedNoteDomId.match(/#note-\d+/)) {
      const $linkedNote = $(linkedNoteDomId);
      if (!$linkedNote.length) return;

      const $noteThread = $linkedNote.closest(".note-thread");
      const searchParams = new URLSearchParams(window.location.search);
      const isReply = searchParams.get("reply") === "true";

      if (isReply || ($noteThread.length && !$linkedNote.is($noteThread.find(".note:first")))) {
        const noteThreadId = $noteThread.prop("id").split("_").pop();
        const $collapsedNotes = $(`#other-thread-notes-thread-${noteThreadId}`);
        if (!$collapsedNotes.hasClass("show")) {
          $collapsedNotes.addClass("show");
          $noteThread.find(".note-thread-reply").addClass("active");
          $noteThread.find(".icon-chevron-show, .icon-chevron-hide").toggle();
        }
      }
      if (isReply) {
        setTimeout(
          () => {
            const scrollOffset = $(window.location.hash).offset().top -
              $("nav.navbar.header").innerHeight();
            $(window).scrollTop(scrollOffset);
            $noteThread.find(".note-thread-reply textarea:first").trigger("focus");
          },
          100,
        );
      } else if ($linkedNote.offset().top === 0) {
        $(".modal").on("shown.bs.modal", () => {
          if ($(".modal-content").height() > window.innerHeight) {
            $("#show").scrollTop($(".modal-content").height() - window.innerHeight);
          }
          $linkedNote.addClass("modal-note-active");
          $(".modal-body").scrollTop($linkedNote.offset().top - $(".modal-body").height());
        });
      } else {
        setTimeout(
          () => {
            const scrollOffset = $(window.location.hash).offset().top -
              $("nav.navbar.header").innerHeight();
            $(window).scrollTop(scrollOffset);
          },
          100,
        );
      }
    }
  }
}
