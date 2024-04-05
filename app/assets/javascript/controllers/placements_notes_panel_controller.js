import { Controller } from '@hotwired/stimulus';
import $ from 'jquery';
import remoteSearch from '../src/ats/remote_search';
import { initBootstrapSelect } from "../src/shared/bootstrap_select";

export default class extends Controller {
  static targets = ['addPlacementAutocomplete'];

  static values = { positionSearchUrl: String };

  connect() {
    initBootstrapSelect($(this.element).find(".selectpicker"));
  }

  disconnect() {
    // Avoid multiple application of `selectize`.
    if (this.hasAddPlacementAutocompleteTarget) {
      this.addPlacementAutocompleteTarget.selectize.destroy();
    }
  }

  addPlacementAutocompleteTargetConnected() {
    this.#initSelectize(
      this.addPlacementAutocompleteTarget,
      this.positionSearchUrlValue
    );
  }

  #initSelectize(obj, searchUrl) {
    const scores = { active: 100, passive: 10, open: 1, on_hold: 0.1, closed: 0.01 };
    // We use client-side rendering here instead of server-side due to errors that occur
    // when passing the default value while sourcing in the Hub.
    function renderOption(item, escape) {
      return (
        `<div class="option selected${item.status === 'on_hold' || item.status === 'open' ? ' text-secondary' : ''}` +
        ` data-selectable="true" data-value="${escape(item.id)}">${escape(item.name)}</div>`
      );
    }
    $(obj).selectize({
      maxItems: 1,
      valueField: 'id',
      searchField: 'name',
      labelField: 'name',
      create: false,
      loadThrottle: 300,
      selectOnTab: true,
      render: { option: renderOption },
      score(search) {
        const score = this.getScoreFunction(search);
        return item => score(item) * scores[item.status];
      },
      load: remoteSearch(obj, searchUrl, 'QUERY'),
    });
  }
}
