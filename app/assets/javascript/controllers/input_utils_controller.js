import { Controller } from "@hotwired/stimulus";

const uriRegex = /^(http(s)?:\/\/(?:www\.|(?!www))[^\s.]+\.[^\s]{2,}|www\.[^\s]+\.[^\s]{2,})$/ig;

export default class extends Controller {
  static targets = ["saveButton", "form", "fieldForDraft"];

  // This function works next way:
  // copy any valid link -> select any text inside editor -> press paste shortcut
  // and a link will be attached to this text.
  pasteAutolink(event) {
    const pastedText = event.paste?.string;
    if (!!pastedText && !!pastedText.match(uriRegex) && !event.paste?.html) {
      const { editor } = event.target;
      const currentSelection = editor.getSelectedRange();

      // Without clearing paste, the pasted text is added 2 times.
      event.paste.string = "";
      editor.recordUndoEntry("Auto Link Paste");
      editor.activateAttribute("href", pastedText);
      if (currentSelection[0] === currentSelection[1]) {
        // Some code in the trix-editor is slow and it needs to wait a bit.
        setTimeout(() => editor.setSelectedRange(currentSelection[1] + pastedText.length), 1);
        return;
      }
      editor.setSelectedRange(currentSelection[1]);
    }
  }
}
