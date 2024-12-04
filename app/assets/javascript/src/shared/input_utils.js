import $ from "jquery";

// Submit a form in a Turbo-friendly way.
function requestSubmitPolyfilled(form) {
  if (form.requestSubmit) {
    form.requestSubmit();
  } else {
    // Polyfill for Safari which doesn't implement this function.
    form.dispatchEvent(new CustomEvent("submit", { bubbles: true }));
  }
}

function activateInstanceSubmit() {
  $(document).on("change", ".instant-submit", function submitForm() {
    if (
      window.performance &&
      window.performance.navigation.type === window.performance.navigation.TYPE_BACK_FORWARD
    ) {
      // If "Back" button was pressed, the form should not be resubmitted because it can
      // cause resubmission of uploaded files.
      return;
    }
    $(this).closest("form").submit();
  });
  $(document).on("change", ".turbo-instant-submit", function submitTurboForm() {
    requestSubmitPolyfilled(this.closest("form"));
  });
}

function activateKeybindShortcuts() {
  $(document).keydown((event) => {
    const $target = $(event.target);
    if ($target.is(":focus") && $target.val() !== "") {
      return true;
    }

    if (event.keyCode === 39) {
      if ($(".arrow-right").length > 0) $(".arrow-right")[0].click();
      return false;
    }

    if (event.keyCode === 37) {
      if ($(".arrow-left").length > 0) $(".arrow-left")[0].click();
      return false;
    }

    return true;
  });
}

function arraysEqual(a, b) {
  return a.length === b.length && a.every((element, index) => element === b[index]);
}

function eventFromRichText(event) {
  return /(trix-editor|textarea)/.test(event.target.tagName.toLowerCase());
}

export {
  activateInstanceSubmit,
  activateKeybindShortcuts,
  arraysEqual,
  requestSubmitPolyfilled,
  eventFromRichText,
};
