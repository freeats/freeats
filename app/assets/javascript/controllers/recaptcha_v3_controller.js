import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["score"];

  scoreTargetConnected(target) {
    // Works when recaptcha_v3_score is calculated on other public pages.
    if (window.atsVisitorScore) target.value = window.atsVisitorScore;
  }
}
