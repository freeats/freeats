import $ from 'jquery';

// Fixes the bug with weird tooltip's behavior
export default function removeTooltips() {
  $('.tooltip')
    .hide()
    .remove();
};
