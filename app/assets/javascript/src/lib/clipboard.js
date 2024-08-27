import $ from "jquery";
import * as clipboard from "clipboard-polyfill";

/* Callback-function for copying content to user's clipboard.
   Element, triggering callback event, should have next attributes:
   1. title - text displayed in tooltip after copying is done;
   2. data-clipboard-text - content that should be copied to clipboard;
   3. data-clipboard-plain-text - (optional) plain-text version of content,
                                  if it uses rich-text format. */
export default async function copyToClip() {
  const richTextContent = $(this).data().clipboardText;
  const plainTextContent = $(this).data().clipboardPlainText || richTextContent;
  const item = new clipboard.ClipboardItem({
    "text/html": new Blob([richTextContent], { type: "text/html" }),
    "text/plain": new Blob([plainTextContent], { type: "text/plain" }),
  });
  $(this).tooltip("show");
  await clipboard.write([item]);
  setTimeout(() => $(this).tooltip("hide"), 1000);
}
