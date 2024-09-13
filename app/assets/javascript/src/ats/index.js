import $ from "jquery";
import initPosition from "./position";

initPosition();

$(document).on("click", ".close-card", (e) => $(e.target).closest(".card").remove());
