import $ from 'jquery';

// Submit a form in a Turbo-friendly way.
function requestSubmitPolyfilled(form) {
  if (form.requestSubmit) {
    form.requestSubmit();
  } else {
    // Polyfill for Safari which doesn't implement this function.
    form.dispatchEvent(new CustomEvent("submit", { bubbles: true }));
  }
}

export default function activateInstanceSubmit() {
  $(document).on('change', '.instant-submit', function submitForm() {
    if (
      window.performance &&
      window.performance.navigation.type === window.performance.navigation.TYPE_BACK_FORWARD
    ) {
      // If "Back" button was pressed, the form should not be resubmitted because it can
      // cause resubmission of uploaded files.
      return;
    }
    $(this).closest('form').submit();
  });
  $(document).on('change', '.turbo-instant-submit', function submitTurboForm() {
    requestSubmitPolyfilled(this.closest('form'));
  });
}
