import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['comment'];

  toggleRequired(event) {
    const { target: { selectedIndex } } = event;
    const select = event.target;
    const reason = select.options[selectedIndex].value;
    const required = (reason === 'other');
    this.commentTarget.required = required;
  }
}
