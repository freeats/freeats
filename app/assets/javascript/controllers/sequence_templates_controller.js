import { Controller } from '@hotwired/stimulus';
import $ from 'jquery';

export default class extends Controller {
  static targets = [
    'position',
    'stage',
    'stagesList'
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

    if (!this.stageTargets[0]) return;

    const delayInputs =
      this.stageTargets
      .map(stage => {
        if ($(stage).is(':visible')) {
          return stage.querySelector('[id$=delay_in_days]');
        }
        return null;
      })
      .filter(delayInput => delayInput);

    const $firstDelay = $(delayInputs[0]);
    $firstDelay.parent().hide();
    $firstDelay.val(0);

    if (!delayInputs[1]) return;

    $(delayInputs[1]).parent().show();
  }
}
