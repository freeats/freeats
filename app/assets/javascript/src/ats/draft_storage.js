export function storeFieldDraft(el) {
  if (!el || !el.id) return;

  const value = el.type === "radio" ? el.checked : el.value;
  localStorage.setItem(el.id, value);
}

export function retrieveFieldDraft(el) {
  if (!el || !el.id) return;

  const storedValue = localStorage.getItem(el.id);
  if (storedValue) {
    if (el.type === "radio") {
      el.checked = storedValue === "true";
    } else {
      el.value = storedValue;
    }
  }
}

export function clearFieldDraft(el) {
  if (el && localStorage.getItem(el.id)) {
    localStorage.removeItem(el.id);
  }
}

export function storeFormDraft(form) {
  [...form.elements].forEach((element) => {
    if (element.type !== "hidden") {
      storeFieldDraft(element);
    }
  });
}

export function retrieveFormDraft(form) {
  if (form) {
    [...form.elements].forEach((element) => {
      if (element.type !== "hidden") {
        retrieveFieldDraft(element);
      }
    });
  }
}

export function clearFormDraft(form) {
  if (form) {
    [...form.elements].forEach((element) => {
      if (element.type !== "hidden") {
        clearFieldDraft(element);
      }
    });
  }
}
