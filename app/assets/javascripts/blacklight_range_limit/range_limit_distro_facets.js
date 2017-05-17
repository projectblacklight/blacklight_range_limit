// for Blacklight.onLoad:
//= require blacklight/core

/* A custom event "plotDrawn.blacklight.rangeLimit" will be sent when flot plot
   is (re-)drawn on screen possibly with a new size. target of event will be the DOM element
   containing the plot.  Used to resize slider to match. */

Blacklight.onLoad(function() {

  // Facets already on the page? Turn em into a chart.
  $(".range_limit .profile .distribution.chart_js ul").each(function() {
      BlacklightRangeLimit.turnIntoPlot($(this).parent());
  });


  // Add AJAX fetched range facets if needed, and add a chart to em
  $(".range_limit .profile .distribution a.load_distribution").each(function() {
      var container = $(this).parent('div.distribution');

      $(container).load($(this).attr('href'), function(response, status) {
          if ($(container).hasClass("chart_js") && status == "success" ) {
            BlacklightRangeLimit.turnIntoPlot(container);
          }
      });
  });

  // Listen for twitter bootstrap collapsible open events, to render flot
  // in previously hidden divs on open, if needed.
  $("body").on("show.bs.collapse", function(event) {
    // Was the target a .facet-content including a .chart-js?
    var container =  $(event.target).filter(".facet-content").find(".chart_js");

    // only if it doesn't already have a canvas, it isn't already drawn
    if (container && container.find("canvas").size() == 0) {
      // be willing to wait up to 1100ms for container to
      // have width -- right away on show.bs is too soon, but
      // shown.bs is later than we want, we want to start rendering
      // while animation is still in progress.
      BlacklightRangeLimit.turnIntoPlot(container, 1100);
    }
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
