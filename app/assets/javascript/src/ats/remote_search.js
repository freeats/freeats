function cleanOptions(selectize) {
  Object.values(selectize.options)
    .forEach((option) => {
      const value = (option.id || option.value).toString();
      if (!selectize.items.includes(value)) selectize.removeOption(value);
    });
}

export default function remoteSearch(target, url, replaceQuery, selectedItems = null) {
  return function query(q, cb) {
    // Remove old not selected options when loading new ones.
    cleanOptions(target.selectize);

    let finalUrl = url.replace(replaceQuery, encodeURIComponent(q));
    if (selectedItems) {
      finalUrl = `${finalUrl}`;
    }
    fetch(finalUrl)
      .then((response) => {
        if (response.ok) return response.json();
        throw new Error(`${response.url}: ${response.statusText}`);
      })
      .then((json) => {
        cb(json);
      })
      .catch((e) => {
        console.error(e);
        cb([]);
      });
  };
}
