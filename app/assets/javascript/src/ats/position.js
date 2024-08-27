import $ from "jquery";

export default function initPosition() {
  $(document).on("change", "#position-status-select", () => {
    const select = document.getElementById("new_change_status_reason");
    const reason = select.options[select.selectedIndex].value;
    const required = reason === "other";
    document.getElementById("position-status-comment").required = required;
  });

  $(document).on("change", "#assigned_only", function submitForm() {
    $(this).closest("form").trigger("submit");
  });
}
