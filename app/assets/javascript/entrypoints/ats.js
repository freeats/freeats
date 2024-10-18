/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/assets/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_include_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

import "../src/shared/bootstrap_activators";
import "../src/shared/global_jquery_loader";
import "../src/shared/modal_remover";
import "@hotwired/turbo-rails";
import "bootstrap";
import "trix";
import "tributejs";

import "../controllers";
import "../src/ats";

// Taken from configuring jquery-ui download page https://jqueryui.com/download/ when toggling
// only "sortable" and "datepicker".
import "jquery-ui/ui/data";
import "jquery-ui/ui/widget";
import "jquery-ui/ui/scroll-parent";
import "jquery-ui/ui/widgets/mouse";
import "jquery-ui/ui/keycode";
import "jquery-ui/ui/widgets/sortable";
import "jquery-ui/ui/widgets/datepicker";

import { initConfirmations } from "../src/shared/confirmations";
import { activateInstanceSubmit, activateKeybindShortcuts } from "../src/shared/input_utils";

initConfirmations();
activateInstanceSubmit();
activateKeybindShortcuts();
