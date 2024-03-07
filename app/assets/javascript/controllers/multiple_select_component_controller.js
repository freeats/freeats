import { Controller } from '@hotwired/stimulus';
import $ from 'jquery';
import 'selectize/dist/js/selectize';
import {
  lock,
  searchParams,
  allowCheckmarkForDisabledOption,
  allowToReSearch,
  applyDeferredData,
  destroySelectize
} from '../src/lib/select_component';

export default class extends Controller {
  static targets = ['select'];

  static values = { buttonGroupSize: String, searchUrl: String };

  selectTargetConnected() {
    // The preloaded options are used to set the initial state of the selectize instance.
    // We may have them when previously the selectize instance was destroyed and we want to restore the state,
    // for example it may happen when we move sections with select fields by the `sortable` library.
    let preloadedOptions = {};
    if (this.selectTarget.dataset.state) {
      preloadedOptions = JSON.parse(this.selectTarget.dataset.state);
      this.selectTarget.removeAttribute('data-state');
    }

    let remoteSearchParams = {};
    if (this.searchUrlValue !== '') {
      remoteSearchParams = searchParams(this.selectTarget, this.searchUrlValue, this.parseOptions);
    }

    $(this.selectTarget).selectize({
      plugins: {
        deselect_options_via_dropdown: {},
        auto_position: {},
        dropdown_buttons: { buttonsClass: 'btn btn-outline-primary',
                            buttonGroupSize: this.buttonGroupSizeValue },
        handle_disabled_options: {},
      },
      selectOnTab: false,
      showArrow: false, //  Hide the default down arrow to replace it with our own.
      ...preloadedOptions,
      ...remoteSearchParams,
    });

    allowCheckmarkForDisabledOption(this.selectTarget.selectize);

    if (this.selectTarget.attributes.readonly) lock(this.selectTarget);

    if (this.searchUrlValue !== '') allowToReSearch(this.selectTarget.selectize);

    applyDeferredData(this.selectTarget.dataset);
  }

  selectTargetDisconnected() {
    destroySelectize(this.selectTarget);
  }

  parseOptions(text) {
    return JSON.parse(text);
  }
}
