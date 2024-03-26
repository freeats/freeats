import $ from 'jquery';

function activateFileUploadInput() {
  $(document).on('change', 'input.upload', function changeButtonAppearance() {
    const $uploadWrapper = $(this).closest('div.file-upload-button');
    $uploadWrapper.find('span').html('Uploaded');
    $uploadWrapper.find('input').click(e => e.preventDefault());
  });
}

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


export { activateFileUploadInput, activateInstanceSubmit };
