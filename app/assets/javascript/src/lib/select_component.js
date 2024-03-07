/* eslint-disable no-param-reassign */
// Remove old not selected options.
function cleanOptions(selectize) {
  Object.values(selectize.options)
  .forEach(option => {
    const value = option.value.toString();
    if (!selectize.items.includes(value)) selectize.removeOption(value);
  });
}

function request(url, cb, parseFunction) {
  fetch(url)
    .then(response => {
      if (response.ok) return response.text();
      throw new Error(`${response.url}: ${response.statusText}`);
    })
    .then(text => {
      cb(parseFunction(text));
    })
    .catch(e => {
      console.error(e); // eslint-disable-line no-console
      cb([]);
    });
}

function remoteSearch(target, url, parseFunction, type) {
  return function query(q, cb) {
    if (q.trim().length < 3){
      cb([]);
      return;
    }

    cleanOptions(target.selectize);

    let finalUrl = url.replace('QUERY', encodeURIComponent(q));
    if (type) finalUrl += `&type=${type}`;

    if (type === 'quick_search') {
      ['candidate', 'lead', 'position', 'company'].forEach((category) => {
        request(`${finalUrl}&searching_for=${category}`, cb, parseFunction);
      });
    } else {
      request(finalUrl, cb, parseFunction);
    }
  };
}

// Simulate the readonly attribute.
export function lock(target) {
  target.selectize.lock();
  target.selectize.$control_input.attr('readonly', true);
}

export function searchParams(target, url, parseFunction, type) {
  return {
    score: () => () => 1, // Restrict ordering results. Order them in the backend.
    load: remoteSearch(target, url, parseFunction, type),
    loadThrottle: 300,
  };
}

// Allow to show the checkmark for disabled options if the option is selected.
export function allowCheckmarkForDisabledOption(selectize) {
  // Patch the selectize method to get the option even if it is disabled.
  selectize.getOption =
    (value) => selectize.getElementWithValue(value, selectize.$dropdown_content.find('.option'));
}

// Clear loaded search values, allow to load them again when the user edits
// the search field several times without changing the focus.
export function allowToReSearch(selectize) {
  selectize.on('type', () => {
    selectize.loadedSearches = {};
  });
}

// Apply deferred data to the selectize instance.
// Solves the problem when data attributes are applied to the original select field,
// and the stimulus controller related to these attributes invokes several times instead of once.
export function applyDeferredData(dataset) {
  Object.keys(dataset).forEach(key => {
    if (key.includes('deferredSelectize')) {
      let newKey = key.replace('deferredSelectize', '');
      newKey = newKey.charAt(0).toLowerCase() + newKey.slice(1);
      dataset[newKey] = dataset[key];
      delete dataset[key];
    }
  });
}

export function destroySelectize(target) {
  // In case if we already destroyed the selectize instance.
  // It could happen in the `array_fields_controller.js`.
  const { selectize } = target;

  let state = null;
  if (selectize) state = {
    options: Object.values(selectize.options),
    items: selectize.items,
  };
  if (selectize) selectize.destroy();

  // Save the state of the selectize instance to restore it later.
  // It could happen in the `array_fields_controller.js` when we move the select field to another place in DOM.
  if (state) target.dataset.state = JSON.stringify(state);
}
