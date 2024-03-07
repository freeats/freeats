import $ from 'jquery';
import { Tooltip } from 'bootstrap';

$(document).on(
  'turbo:load',
  () => new Tooltip('body', { selector: '[data-bs-toggle="tooltip"]', trigger: 'hover' }),
);
