import { Controller } from '@hotwired/stimulus';
import $ from 'jquery';
import 'selectize/dist/js/selectize';
import {
  lock,
  searchParams,
  allowToReSearch,
  applyDeferredData,
  destroySelectize
} from '../src/lib/select_component';

export default class extends Controller {
  static targets = ['select'];

  static values = { searchUrl: String };

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

    const plugins = ['auto_position'];
    // Do not show the remove button if the select field is readonly or disabled.
    const { attributes } = this.selectTarget;
    if (!attributes.readonly && !attributes.disabled) plugins.push('remove_button');

    $(this.selectTarget).selectize({
      plugins,
      selectOnTab: false,
      showArrow: false, //  Hide the default down arrow to replace it with our own.
      ...preloadedOptions,
      ...remoteSearchParams,
    });

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
