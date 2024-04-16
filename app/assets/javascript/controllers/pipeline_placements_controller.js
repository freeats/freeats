import { Controller } from '@hotwired/stimulus';
import $ from 'jquery';
import { initBootstrapSelect } from "../src/shared/bootstrap_select";
import { removeTooltips } from '../src/shared/tooltips';

export default class extends Controller {
  connect() {
    $(this.element).find('form').submit(
      (event) => {
        const $form = $(event.target);
        $form.find(':input[type=submit]').prop('disabled', true);
      }
    );
    initBootstrapSelect($(this.element).find(".selectpicker"));
    removeTooltips();
  }
}
