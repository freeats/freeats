import $ from 'jquery';

// Fixes the bug with weird tooltip's behavior
// eslint-disable-next-line import/prefer-default-export
export function removeTooltips() {
  $('.tooltip')
    .hide()
    .remove();
};
