import { Controller } from "@hotwired/stimulus";
import { Popover } from "bootstrap";
import copyToClip from "../src/lib/clipboard";
import copyIcon from "@tabler/icons/outline/copy.svg";

export default class extends Controller {
  static values = { linkWithPopover: Boolean };

  connect() {
    let { element } = this;

    if (this.linkWithPopoverValue) {
      element = this.#createPopoverWithButton(element);
      if (this.element.dataset.copyLinkShorten) return;
    } else if (element.id === "global-share-link-button-with-content") {
      element.addEventListener("click", this.#utmLinks);
    } else if (element.dataset.slashtag) {
      element.addEventListener("click", this.#inviteLink);
      return;
    }

    element.addEventListener("click", copyToClip);
  }

  #createPopoverWithButton(element) {
    const button = document.createElement("button");
    const tooltipText = element.dataset.copyLinkTooltip;
    const htmlTextToClipboard = element.dataset.copyLinkHtmlText;
    const plainTextToClipboard = element.dataset.copyLinkPlainText;

    this.insertSvgIcon(
      button,
      copyIcon,
      { "stroke-width": 1.25, class: ["icon-component", "icon-component-small"] },
    );

    if (tooltipText && tooltipText !== "") {
      button.innerHTML = [`<span class="me-2">${tooltipText}</span>`, button.innerHTML].join("");
    }

    const { href } = element;
    let defaultPlainText = href;
    let defaultHref = href;

    if (href.startsWith("tel:")) {
      defaultPlainText = href.slice("tel:".length);
    } else if (href.startsWith("mailto:")) {
      defaultPlainText = href.slice("mailto:".length);
    } else if (href.includes("mail_to=")) {
      defaultPlainText = unescape(href.split("mail_to=").pop());
      defaultHref = `mailto:${defaultPlainText}`;
    }

    const plainText = plainTextToClipboard || defaultPlainText;
    const htmlText = htmlTextToClipboard || `<a href=${defaultHref}>${plainText}</a>`;

    button.setAttribute("data-clipboard-text", htmlText);
    button.setAttribute("data-clipboard-plain-text", plainText);
    button.setAttribute("type", "button");
    button.setAttribute("class", "btn btn-link p-0");
    button.setAttribute("data-bs-trigger", "manual");
    button.setAttribute("data-bs-placement", "bottom");
    button.setAttribute("data-bs-title", "Copied!");

    if (element.dataset.copyLinkShorten) {
      button.addEventListener("click", async () => {
        const response = await fetch(`/shorten_link?link=${encodeURIComponent(href)}`);
        const data = await response.text();
        if (!plainTextToClipboard) {
          button.dataset.clipboardPlainText = data;
        }
        if (!htmlTextToClipboard) {
          button.dataset.clipboardText = `<a href=${data}>${plainTextToClipboard || data}</a>`;
        }
        copyToClip.call(button);
        button.addEventListener("click", copyToClip);
      }, { once: true });
    }

    const popover = new Popover(element, {
      trigger: "hover",
      html: true,
      content: button,
      delay: { show: 400, hide: 5000 },
      customClass: "copy-to-clipboard-tooltip",
    });

    // Close when clicking the button to copy.
    button.addEventListener("click", () => {
      setTimeout(() => popover.hide(), 1000);
      return false;
    });
    // Do not close on missclick near the button.
    element.addEventListener(
      "shown.bs.popover",
      () =>
        document.querySelector(".popover").addEventListener("click", (e) => e.stopPropagation()),
    );
    // Closes when another is shown.
    element.addEventListener("show.bs.popover", () => {
      const shownPopover = document.querySelectorAll(
        '[data-copy-to-clipboard-link-with-popover-value="true"]',
      );
      if (shownPopover.length === 0) return;
      shownPopover.forEach((elem) => Popover.getInstance(elem).hide());
    });
    // Close when clicking anywhere else.
    document.addEventListener("click", () => popover.hide());

    return button;
  }

  #utmLinks(event) {
    const utmContent = prompt("What should utm_content be? Leave empty to exclude it.");
    if (!utmContent) return event.preventDefault();
    const linkInput = event.currentTarget;
    const link = new URL(linkInput.dataset.clipboardPlainText);
    if (utmContent.length > 0) {
      link.searchParams.set("utm_content", utmContent);
    } else {
      link.searchParams.delete("utm_content");
    }
    linkInput.dataset.clipboardPlainText = link.href;
    return "";
  }

  async #inviteLink() {
    this.classList.add("disabled");
    const { longLink, text, slashtag, isLink } = this.dataset;
    const shortLink = `https://tbyte.co/${slashtag}`;
    const subject = "Job opportunities from Toughbyte";
    let linkWithMailTo = "mailto:?";
    if (this.dataset.clipboardPlainText === undefined) {
      const response = await fetch(
        `/shorten_link.json?link=${encodeURIComponent(longLink)}&slashtag=${slashtag}`,
      );
      if (response.ok) {
        this.setAttribute("data-clipboard-plain-text", text.replace("*shorten-link*", shortLink));
      } else {
        this.setAttribute("data-clipboard-plain-text", text.replace("*shorten-link*", longLink));
      }
      if (isLink) {
        linkWithMailTo += `subject=${subject}&`;
      }
    }
    if (isLink) {
      window.location.href = `${linkWithMailTo}body=${
        encodeURIComponent(this.dataset.clipboardPlainText)
      }`;
    }
    const event = new Event("triggerCopy");
    this.addEventListener("triggerCopy", copyToClip);
    this.dispatchEvent(event);
    setTimeout(() => this.classList.remove("disabled"), 500);
  }

  // TODO: move it to something like tabler icons utils
  // and make a dynamic import by a name
  insertSvgIcon(element, icon, options) {
    element.innerHTML = icon;
    const svgIcon = element.querySelector("svg");

    for (const [key, value] of Object.entries(options)) {
      if (key === "class") {
        Array.isArray(value)
          ? value.forEach((className) => svgIcon.classList.add(className))
          : svgIcon.classList.add(value);
        continue;
      }
      svgIcon.setAttribute(key, value);
    }

    return element;
  }
}
