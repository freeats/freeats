document.addEventListener("turbo:before-render", () => {
  if (document.getElementsByClassName("modal").length === 0) return;

  const turboModalWindow = document.getElementById("turbo_modal_window");

  turboModalWindow.removeAttribute("src");
  turboModalWindow.replaceChildren();
});
