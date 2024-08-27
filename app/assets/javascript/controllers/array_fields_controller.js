import { Controller } from "@hotwired/stimulus";
import $ from "jquery";

export default class extends Controller {
  static values = {
    className: String,
    fieldName: String,
    sortable: Boolean,
  };

  connect() {
    if (this.sortableValue) {
      $(this.element).sortable({
        handle: ".sortable-handle",
        cursor: "move",
      });
    }
  }

  addField() {
    const pluralFieldName = this.#pluralizeFieldName(this.fieldNameValue);
    const fieldTemplate = document.getElementById(
      `${this.classNameValue}_${pluralFieldName}_hidden`,
    );
    const fieldIds = [...this.element.querySelectorAll(`.array-unit:not(#${fieldTemplate.id})`)]
      .map((el) => +el.id.slice(`${this.classNameValue}_${pluralFieldName}`.length));
    const id = fieldIds.length ? Math.max(...fieldIds) + 1 : 1;

    this.deSelectize(fieldTemplate);

    const newField = fieldTemplate.cloneNode(true);
    newField.removeAttribute("hidden", false);
    newField.setAttribute("disabled", false);
    newField.setAttribute("id", `${this.classNameValue}_${pluralFieldName}${id}`);

    // Update attributes for email address fields.
    [...newField.querySelectorAll("[id*=_id_]")].forEach((el) => {
      el.setAttribute("name", el.name.replace("[id]", `[${id}]`));
      el.setAttribute("id", el.id.replace("_id_", `_${id}_`));
      el.setAttribute("data-array-fields-block-id-param", el.id.replace("_id_", `_${id}_`));
    });

    const deleteButton = newField.querySelector(
      `.${this.classNameValue}-delete-${this.fieldNameValue}-button`,
    );
    if (deleteButton) {
      deleteButton.setAttribute(
        "id",
        `${this.classNameValue}_delete_${this.fieldNameValue}_button${id}`,
      );
      deleteButton.setAttribute("data-array-fields-block-id-param", newField.id);
    }

    this.element.insertBefore(newField, fieldTemplate);
  }

  deleteField({ params: { blockId } }) {
    document.getElementById(blockId).remove();
  }

  #pluralizeFieldName(fieldName) {
    if (fieldName.endsWith("y")) {
      return `${fieldName.slice(0, -1)}ies`;
    }
    return `${fieldName}s`;
  }

  // De-selectize select fields to prevent the problem with double initialization of selectize.
  deSelectize(section) {
    section.querySelectorAll(".select-component select").forEach((el) => {
      const { selectize } = el;
      if (selectize) selectize.destroy();
    });
  }
}
