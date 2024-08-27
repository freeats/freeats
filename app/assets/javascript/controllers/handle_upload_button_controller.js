import { Controller } from "@hotwired/stimulus";
import $ from "jquery";
import { atsConfirm } from "../src/shared/confirmations";

export default class extends Controller {
  static targets = ["input", "text"];

  inputTargetConnected() {
    this.inputTarget.addEventListener("change", (event) => {
      const fileSize = this.inputTarget.files[0].size;
      const nginxFileSizeLimitInMegaBytes = window.gon.nginx_file_size_limit_in_mega_bytes;

      if (fileSize > nginxFileSizeLimitInMegaBytes * 1024 * 1024) {
        this.displayAlert(this.inputTarget, nginxFileSizeLimitInMegaBytes);
        this.inputTarget.value = "";
        this.textTarget.textContent = "Upload";

        event.stopPropagation();
        return false;
      }

      this.textTarget.textContent = "Uploaded";

      return true;
    });
  }

  // Browser restricts simulating a click event on the input field,
  // we need to use the `atsConfirm` directly.
  displayAlert(target, nginxFileSizeLimitInMegaBytes) {
    target.dataset.title = `Please choose a file smaller than ${nginxFileSizeLimitInMegaBytes} MB`;
    target.dataset.btnOkLabel = "Choose";
    target.dataset.btnCancelLabel = "Cancel";
    $(target).data("confirm", "false");

    atsConfirm.call(target);
  }
}
