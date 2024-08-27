import "bootstrap";
import bootbox from "bootbox";
// Bootbox 6 compatibility problem with bootstrap 5
// https://github.com/bootboxjs/bootbox/issues/833#issuecomment-1450261337
import $ from "./global_jquery_loader";

export function atsConfirm() {
  const $atsConfirmBtn = $(this);
  const { form } = $atsConfirmBtn.get()[0];

  if (form !== undefined && !form.checkValidity()) {
    return null;
  }

  if ($atsConfirmBtn.data("confirm") === "true") return true;

  const title = $atsConfirmBtn.data("title") || "Are you sure?";
  const content = $atsConfirmBtn.data("content");
  const size = $atsConfirmBtn.data("size");
  const center = $atsConfirmBtn.data("center");
  bootbox.confirm({
    title: title ?? content,
    message: content ?? " ",
    swapButtonOrder: false,
    size,
    centerVertical: center,
    buttons: {
      confirm: {
        label: $atsConfirmBtn.data("btn-ok-label") || "Yes",
        className: $atsConfirmBtn.data("btn-ok-class") || "btn-primary btn-small",
      },
      cancel: {
        label: $atsConfirmBtn.data("btn-cancel-label") || "No",
        className: $atsConfirmBtn.data("btn-cancel-class") || "btn-light border btn-small",
      },
    },
    callback(result) {
      if (result) {
        $atsConfirmBtn.data("confirm", "true");
        $atsConfirmBtn.click();
      }
    },
    onShow: (e) => {
      if (!content) {
        e.target.querySelector(".modal-body")?.remove();
        e.target.querySelector(".modal-footer")?.classList.add("border-top-0");
      }
    },
  });
  return false;
}

export function initConfirmations() {
  $(document).on("click", "[data-toggle=ats-confirmation]", atsConfirm);
}
