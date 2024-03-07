import { Controller } from '@hotwired/stimulus';
import $ from 'jquery';
import 'selectize/dist/js/selectize';
import { enableQuickSearchListeners, disableQuickSearchListeners } from '../src/lib/quick_search';
import {
  lock,
  searchParams,
  allowToReSearch,
  applyDeferredData,
  destroySelectize
} from '../src/lib/select_component';


export default class extends Controller {
  static targets = ['select'];

  static values = {
    searchUrl: String,
    options: String,
    itemAsRichText: Boolean,
    type: String,
  };

  selectTargetConnected() {
    // The preloaded options are used to set the initial state of the selectize instance.
    // We may have them when previously the selectize instance was destroyed and we want to restore the state,
    // for example it may happen when we move sections with select fields by the `sortable` library.
    // Also we may have preloaded options for exactly this select field because the Rails select helpers
    // can`t work correclty with rich text in the options, and we have to pass them as a stimulus controller value.
    let preloadedOptions = {};
    if (this.selectTarget.dataset.state) {
      preloadedOptions = JSON.parse(this.selectTarget.dataset.state);
      this.selectTarget.removeAttribute('data-state');
    } else if (this.optionsValue !== '') {
      const parsedOptions = this.parseOptions(this.optionsValue);
      preloadedOptions = {
        options: parsedOptions,
        items: this.selectedOptions(parsedOptions),
      };
    }

    let remoteSearchParams = {};
    if (this.searchUrlValue !== '') {
      remoteSearchParams = searchParams(this.selectTarget, this.searchUrlValue, this.parseOptions, this.typeValue);
    }

    // Allow to render the selected option as rich text or as plain text.
    const renderItem = this.itemAsRichTextValue ? 'html' : 'label';

    $(this.selectTarget).selectize({
      plugins: ['auto_position'],
      showArrow: false, //  Hide the default down arrow to replace it with our own.
      selectOnTab: false,
      searchField: 'html',
      ...preloadedOptions,
      ...remoteSearchParams,
      ...this.quickSearchParams(this.typeValue),
      render: {
        option: data => `<div class="option">${data.html}</div>`,
        item: data => `<div class="item">${data[renderItem]}</div>`,
        optgroup_header: () => '<div></div>', // Hide the optgroup header, used for the quick search.
      },
    });

    if (this.selectTarget.attributes.readonly) lock(this.selectTarget);

    if (this.searchUrlValue !== '') allowToReSearch(this.selectTarget.selectize);

    if (this.typeValue === 'quick_search') enableQuickSearchListeners(document, this.selectTarget.selectize);

    applyDeferredData(this.selectTarget.dataset);
  }

  selectTargetDisconnected() {
    destroySelectize(this.selectTarget);

    if (this.typeValue === 'quick_search') disableQuickSearchListeners(document);
  }

  parseOptions(text) {
    const options = [];
    const parser = new DOMParser();
    const doc = parser.parseFromString(text, 'text/html');

    doc.querySelectorAll('option').forEach((option) => {
      const attributes =
        Object.values(option.attributes).reduce((acc, attr) => {
          acc[attr.name] = attr.value;
          return acc;
        }, {});

      options.push({html: option.innerHTML,...attributes,});
    });

    return options;
  }

  selectedOptions(options) {
    return options.reduce((acc, option) => {
      if (option.selected) acc.push(option.value);
      return acc;
    }, []);
  }

  quickSearchParams(type) {
    if (type !== 'quick_search') return {};

    return {
      optgroups: [
        { value: 'candidate'},
        { value: 'lead'},
        { value: 'position'},
        { value: 'company'},
      ],
      lockOptgroupOrder: true,
    };
  }
}
