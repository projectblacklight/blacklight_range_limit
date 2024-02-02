/**
 * BlacklightRangeLimit module setup.
 */
'use strict';

const BlacklightRangeLimit = {}

BlacklightRangeLimit.display_ratio = 1/(1.618 * 2); // half a golden rectangle, why not
/* A custom event "plotDrawn.blacklight.rangeLimit" will be sent when flot plot
    is (re-)drawn on screen possibly with a new size. target of event will be the DOM element
    containing the plot.  Used to resize slider to match. */
BlacklightRangeLimit.redrawnEvent = "plotDrawn.blacklight.rangeLimit";

// takes a string and parses into an integer, but throws away commas first, to avoid truncation when there is a comma
// use in place of javascript's native parseInt
BlacklightRangeLimit.parseNum = function parseNum(str) {
  str = String(str).replace(/[^0-9-]/g, '');
  return parseInt(str, 10);
};

BlacklightRangeLimit.form_selection = function form_selection(form, min, max) {
  var begin_val = BlacklightRangeLimit.parseNum($(form).find("input.range_begin").val());
  if (isNaN(begin_val) || begin_val < min) {
    begin_val = min;
  }
  var end_val = BlacklightRangeLimit.parseNum($(form).find("input.range_end").val());
  if (isNaN(end_val) || end_val > max) {
    end_val = max;
  }

  return BlacklightRangeLimit.normalized_selection(begin_val, end_val);
}

// Add AJAX fetched range facets if needed, and add a chart to em
BlacklightRangeLimit.checkForNeededFacetsToFetch = function checkForNeededFacetsToFetch() {
  $(".range_limit .profile .distribution a.load_distribution").each(function() {
    var container = $(this).parent('div.distribution');

    $(container).load($(this).attr('href'), function(response, status) {
      if ($(container).hasClass("chart_js") && status == "success" ) {
        BlacklightRangeLimit.turnIntoPlot(container);
        }
    });
  });
}

BlacklightRangeLimit.function_for_find_segment = function function_for_find_segment(pointer_lookup_arr) {
  return function(x_coord) {
    for (var i = pointer_lookup_arr.length-1 ; i >= 0 ; i--) {
      var hash = pointer_lookup_arr[i];
      if (x_coord >= hash.from)
        return hash;
    }
    return pointer_lookup_arr[0];
  };
}

// Send endpoint to endpoint+0.99999 to have display
// more closely approximate limiting behavior esp
// at small resolutions. (Since we search on whole numbers,
// inclusive, but flot chart is decimal.)
BlacklightRangeLimit.normalized_selection = function normalized_selection(min, max) {
  max += 0.99999;

  return {xaxis: { 'from':min, 'to':max}}
}

// Check if Flot is loaded
BlacklightRangeLimit.domDependenciesMet = function domDependenciesMet() {
  return typeof $.plot != "undefined"
}

// Support for Blacklight 7 and 8:
BlacklightRangeLimit.modalSelector = '#blacklight-modal' // Blacklight.modal?.modalSelector || Blacklight.Modal.modalSelector

BlacklightRangeLimit.modalObserverConfig = {
  attributes: true,
}

BlacklightRangeLimit.initSliderModalObserver = function() {
  // Use a mutation observer to detect when the modal dialog is open
  const modalObserver = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.attributeName !== 'open') {return;}
      if (mutation.target.hasAttribute('open')) {
        $(BlacklightRangeLimit.modalSelector).find(".range_limit .profile .range.slider_js").each(function() {
          BlacklightRangeLimit.buildSlider(this);
        });
      }
    });
  });
  modalObserver.observe($(BlacklightRangeLimit.modalSelector)[0], BlacklightRangeLimit.modalObserverConfig);
}

BlacklightRangeLimit.initPlotModalObserver = function() {
  // Use a mutation observer to detect when the modal dialog is open
  const modalObserver = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.attributeName !== 'open') {return;}
      if (mutation.target.hasAttribute('open')) {
        $(BlacklightRangeLimit.modalSelector).find(".range_limit .profile .distribution.chart_js ul").each(function() {
          BlacklightRangeLimit.turnIntoPlot($(this).parent());
        });

        // Case when there is no currently selected range
        BlacklightRangeLimit.checkForNeededFacetsToFetch();
      }
    });
  });
  modalObserver.observe($(BlacklightRangeLimit.modalSelector)[0], BlacklightRangeLimit.modalObserverConfig);
}

export default BlacklightRangeLimit;
