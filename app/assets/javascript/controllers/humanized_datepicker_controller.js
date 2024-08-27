import { Controller } from "@hotwired/stimulus";
import $ from "jquery";

export default class extends Controller {
  static targets = ["datepicker", "datepickerAlt"];

  connect() {
    $(this.datepickerTarget).datepicker({
      dateFormat: "yy-mm-dd",
      firstDay: 1,
      beforeShow: (_, inst) => this.#setDatepickerPos(_, inst),
      onSelect: (date) => {
        this.updateDatepickerAlt();
        this.updateDatepicker(date);
      },
    });
    this.updateDatepickerAlt();
    $(this.datepickerTarget).datepicker("setDate", this.datepickerTarget.value);
  }

  showDatepicker(e) {
    e.preventDefault();
    $(this.datepickerTarget).datepicker("show");
  }

  updateDatepicker(date) {
    $(this.datepickerTarget).val(date);
    $(this.datepickerTarget).attr("value", date);
    $(this.datepickerTarget).trigger("change");
  }

  updateDatepickerAlt() {
    const $altTarget = $(this.datepickerAltTarget);
    const currentValue = $(this.datepickerTarget).val().toString();
    if (currentValue === "") {
      $altTarget.val("");
      return;
    }

    const valueDate = new Date(currentValue);
    valueDate.setHours(0, 0, 0, 0);
    const todayDate = new Date();
    todayDate.setHours(0, 0, 0, 0);
    const yesterdayDate = new Date();
    yesterdayDate.setDate(todayDate.getDate() - 1);
    yesterdayDate.setHours(0, 0, 0, 0);
    const tomorrowDate = new Date();
    tomorrowDate.setDate(todayDate.getDate() + 1);
    tomorrowDate.setHours(0, 0, 0, 0);

    if (+valueDate === +todayDate) {
      $altTarget.val("Today");
    } else if (+valueDate === +yesterdayDate) {
      $altTarget.val("Yesterday");
    } else if (+valueDate === +tomorrowDate) {
      $altTarget.val("Tomorrow");
    } else {
      const weekFromDate = new Date();
      weekFromDate.setDate(todayDate.getDate() + 6);
      weekFromDate.setHours(0, 0, 0, 0);
      if (+todayDate <= +valueDate && +valueDate <= +weekFromDate) {
        $altTarget.val(new Intl.DateTimeFormat("en-US", { weekday: "long" }).format(valueDate));
      } else if (+todayDate.getFullYear() === +valueDate.getFullYear()) {
        $altTarget.val(
          new Intl.DateTimeFormat("en-US", { month: "short", day: "numeric" }).format(valueDate),
        );
      } else {
        $altTarget.val(
          new Intl.DateTimeFormat("en-US", { year: "numeric", month: "short", day: "numeric" })
            .format(valueDate),
        );
      }
    }
  }

  #setDatepickerPos(_, inst) {
    // The position of the visible input field is taken here,
    // as it is always 0,0 for the hidden one.
    const rect = this.datepickerAltTarget.getBoundingClientRect();
    const calendarHeight = inst.dpDiv.height();
    let topOffset = rect.bottom;
    const freeSpaceAtBottom = window.innerHeight - topOffset;

    if (freeSpaceAtBottom < calendarHeight) {
      // If the calendar fits by covering the input field.
      if (freeSpaceAtBottom + rect.height > calendarHeight) {
        topOffset = rect.top;
        // If there's enough space at the top for a calendar.
      } else if (window.innerHeight - freeSpaceAtBottom - rect.height > calendarHeight) {
        topOffset = rect.top - calendarHeight;
      } else {
        topOffset = 0;
      }
    }
    // Use 'setTimeout' to prevent effect overridden by other scripts.
    setTimeout(() => {
      inst.dpDiv.css({ top: topOffset });
    }, 0);
  }
}
