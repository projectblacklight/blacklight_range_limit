// Master manifest file for engine, so local app can require
// this one file, but get all our files -- and local app
// require does not need to change if we change file list.
//
// Note JQuery is required to be loaded for flot and blacklight_range_limit
// JS to work, expect host app to load it.


//= require 'flot/jquery.canvaswrapper.js'
//= require 'flot/jquery.colorhelpers.js'
//= require 'flot/jquery.flot.js'
//= require 'flot/jquery.flot.browser.js'
//= require 'flot/jquery.flot.saturated.js'
//= require 'flot/jquery.flot.drawSeries.js'
//= require 'flot/jquery.event.drag.js'
//= require 'flot/jquery.flot.hover.js'
//= require 'flot/jquery.flot.uiConstants.js'
//= require 'flot/jquery.flot.selection.js'
//= require 'bootstrap-slider'

//= require 'blacklight_range_limit/blacklight_range_limit.umd'

Blacklight.onLoad(function() {
  // Support for Blacklight 7 and 8:
  modalSelector = Blacklight.modal?.modalSelector || Blacklight.Modal.modalSelector
  BlacklightRangeLimit.initialize(modalSelector)
})