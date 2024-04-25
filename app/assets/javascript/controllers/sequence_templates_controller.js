import { Controller } from '@hotwired/stimulus';
import $ from 'jquery';

export default class extends Controller {
  static targets = [
    'position',
    'stagesList',
    'delay'
  ];

  connect() {
    if (!this.hasStagesListTarget) return;

    this.updateStages();
    const $stagesList = $(this.stagesListTarget);
    $stagesList.on('cocoon:after-insert', () => {
      this.updateStages();
    });
    $stagesList.on('cocoon:after-remove', () => {
      this.updateStages();
    });
    $stagesList.on('click', '.trix-button--icon-link', e => {
      const $linkButton = $(e.target);
      $linkButton.closest('trix-toolbar').find('input[name=href]').prop('type', 'text');
    });
  }

  updateStages() {
    let index = 1;
    this.positionTargets.forEach(position => {
      const $positionContainer = $(position);
      if ($positionContainer.is(':visible')) {
        $positionContainer.children('input').val(index);
        $positionContainer.children('.stage-position').text(index);
        index += 1;
      }
    });

    if (!this.delayTargets[0]) return;

    const $firstDelay = $(this.delayTargets[0]);
    $firstDelay.hide();
    $firstDelay.find('input').val(0);
    if (!this.delayTargets[1]) return;

    $(this.delayTargets[1]).show();
  }
}
