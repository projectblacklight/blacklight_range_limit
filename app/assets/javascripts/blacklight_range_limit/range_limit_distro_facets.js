// for Blacklight.onLoad:

/**
 * Closure functions in this file are mainly concerned with initializing, resizing, and updating
 * range limit functionality based off of page load, facet opening, page resizing, and otherwise
 * events.
 */

Blacklight.onLoad(function() {

  // Facets already on the page? Turn em into a chart.
  $(".range_limit .profile .distribution.chart_js ul").each(function() {
      BlacklightRangeLimit.turnIntoPlot($(this).parent());
  });

  BlacklightRangeLimit.checkForNeededFacetsToFetch();

  // Listen for twitter bootstrap collapsible open events, to render flot
  // in previously hidden divs on open, if needed.
  $("body").on("show.bs.collapse", function(event) {
    // Was the target a .facet-content including a .chart-js?
    var container =  $(event.target).filter(".facet-content").find(".chart_js");

    // only if it doesn't already have a canvas, it isn't already drawn
    if (container && container.find("canvas").length == 0) {
      // be willing to wait up to 1100ms for container to
      // have width -- right away on show.bs is too soon, but
      // shown.bs is later than we want, we want to start rendering
      // while animation is still in progress.
      BlacklightRangeLimit.turnIntoPlot(container, 1100);
    }
  });

  // When loaded in a modal
  $(Blacklight.modal.modalSelector).on('shown.bs.modal', function() {
    $(this).find(".range_limit .profile .distribution.chart_js ul").each(function() {
      BlacklightRangeLimit.turnIntoPlot($(this).parent());
    });

    // Case when there is no currently selected range
    BlacklightRangeLimit.checkForNeededFacetsToFetch();
  });

  $("body").on("shown.bs.collapse", function(event) {
    var container =  $(event.target).filter(".facet-content").find(".chart_js");
    BlacklightRangeLimit.redrawPlot(container);
  });

  // debouce borrowed from underscore
  // Returns a function, that, as long as it continues to be invoked, will not
  // be triggered. The function will be called after it stops being called for
  // N milliseconds. If `immediate` is passed, trigger the function on the
  // leading edge, instead of the trailing.
  debounce = function(func, wait, immediate) {
    var timeout;
    return function() {
      var context = this, args = arguments;
      var later = function() {
        timeout = null;
        if (!immediate) func.apply(context, args);
      };
      var callNow = immediate && !timeout;
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
      if (callNow) func.apply(context, args);
    };
  };

  $(window).on("resize", debounce(function() {
    $(".chart_js").each(function(i, container) {
      BlacklightRangeLimit.redrawPlot($(container));
    });
  }, 350));
});
