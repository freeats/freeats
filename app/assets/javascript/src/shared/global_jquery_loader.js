// We need to make jQuery available globally for Bootstrap 5 to pick it up and allow using it.
// https://stackoverflow.com/a/67990543

import $ from "jquery";

window.$ = $;
window.jQuery = $;

// Bootbox 6 compatibility problem with bootstrap 5
// https://github.com/bootboxjs/bootbox/issues/833#issuecomment-1450261337
export default $;
