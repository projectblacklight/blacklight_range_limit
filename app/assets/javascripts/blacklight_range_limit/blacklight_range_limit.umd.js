(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
  typeof define === 'function' && define.amd ? define(factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.BlacklightRangeLimit = factory());
})(this, (function () { 'use strict';

  /**
   * BlacklightRangeLimit module setup.
   */

  const BlacklightRangeLimit = {};

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
  };

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
  };

  BlacklightRangeLimit.function_for_find_segment = function function_for_find_segment(pointer_lookup_arr) {
    return function(x_coord) {
      for (var i = pointer_lookup_arr.length-1 ; i >= 0 ; i--) {
        var hash = pointer_lookup_arr[i];
        if (x_coord >= hash.from)
          return hash;
      }
      return pointer_lookup_arr[0];
    };
  };

  // Send endpoint to endpoint+0.99999 to have display
  // more closely approximate limiting behavior esp
  // at small resolutions. (Since we search on whole numbers,
  // inclusive, but flot chart is decimal.)
  BlacklightRangeLimit.normalized_selection = function normalized_selection(min, max) {
    max += 0.99999;

    return {xaxis: { 'from':min, 'to':max}}
  };

  // Check if Flot is loaded
  BlacklightRangeLimit.domDependenciesMet = function domDependenciesMet() {
    return typeof $.plot != "undefined"
  };

  // Support for Blacklight 7 and 8:
  BlacklightRangeLimit.modalSelector = '#blacklight-modal'; // Blacklight.modal?.modalSelector || Blacklight.Modal.modalSelector

  BlacklightRangeLimit.modalObserverConfig = {
    attributes: true,
  };

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
  };

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
  };

  /**
   * Closure functions in this file are mainly concerned with initializing, resizing, and updating
   * range limit functionality based off of page load, facet opening, page resizing, and otherwise
   * events.
   */

  const RangeLimitDistroFacet = {
    initialize: function(modalSelector) {
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
      $(modalSelector).on('shown.bs.modal', function() {
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
      const debounce = function(func, wait, immediate) {
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
    }
  };

  const RangeLimitSlider = {
    initialize: function(modalSelector) {
      $(".range_limit .profile .range.slider_js").each(function() {
        BlacklightRangeLimit.buildSlider(this);
      });

      // For Blacklight < 8, when loaded in a modal
      $(modalSelector).on('shown.bs.modal', function() {
        $(this).find(".range_limit .profile .range.slider_js").each(function() {
          BlacklightRangeLimit.buildSlider(this);
        });
      });

      // For Blacklight 8, use a mutation observer to detect when the HTML dialog is open
      BlacklightRangeLimit.initSliderModalObserver();

      // catch event for redrawing chart, to redraw slider to match width
      $("body").on("plotDrawn.blacklight.rangeLimit", function(event) {
        var area       = $(event.target).closest(".limit_content.range_limit");
        var plot       = area.find(".chart_js").data("plot");
        var slider_el  = area.find(".slider");

        if (plot && slider_el) {
          slider_el.width(plot.width());
          slider_el.css("display", "block");
        }
      });
    }
  };

  // returns two element array min/max as numbers. If there is a limit applied,
  // it's boundaries are are limits. Otherwise, min/max in current result
  // set as sniffed from HTML. Pass in a DOM element for a div.range
  // Will return NaN as min or max in case of error or other weirdness.
  BlacklightRangeLimit.min_max = function min_max(range_element) {
    var current_limit =  $(range_element).closest(".limit_content.range_limit").find(".current");
    let min, max;
    min = max = BlacklightRangeLimit.parseNum(current_limit.find(".single").data('blrlSingle'));
    if ( isNaN(min)) {
      min = BlacklightRangeLimit.parseNum(current_limit.find(".from").first().data('blrlBegin'));
      max = BlacklightRangeLimit.parseNum(current_limit.find(".to").first().data('blrlEnd'));
    }

    if (isNaN(min) || isNaN(max)) {
      //no current limit, take from results min max included in spans
      min = BlacklightRangeLimit.parseNum($(range_element).find(".min").first().text());
      max = BlacklightRangeLimit.parseNum($(range_element).find(".max").first().text());
    }
    return [min, max]
  };


  // Check to see if a value is an Integer
  // see: http://stackoverflow.com/questions/3885817/how-to-check-if-a-number-is-float-or-integer
  BlacklightRangeLimit.isInt = function isInt(n) {
    return n % 1 === 0;
  };

  BlacklightRangeLimit.buildSlider = function buildSlider(thisContext) {
      var range_element = $(thisContext);

      var boundaries = BlacklightRangeLimit.min_max(thisContext);
      var min = boundaries[0];
      var max = boundaries[1];

      if (BlacklightRangeLimit.isInt(min) && BlacklightRangeLimit.isInt(max)) {
        $(thisContext).contents().wrapAll('<div class="sr-only visually-hidden" />');

        var range_element = $(thisContext);
        var form = $(range_element).closest(".range_limit").find("form.range_limit");
        var begin_el = form.find("input.range_begin");
        var end_el = form.find("input.range_end");

        var placeholder_input = $('<input type="hidden" data-slider-placeholder="true" />').appendTo(range_element);

        // make sure slider is loaded
        if (placeholder_input.slider !== undefined) {
          placeholder_input.slider({
            min: min,
            max: max,
            value: [min, max],
            tooltip: "hide"
          });

          // try to make slider width/orientation match chart's
          var container = range_element.closest(".range_limit");
          var plot_el = container.find(".chart_js");
          var plot = plot_el.data("plot");
          var slider_el = container.find(".slider");

          if (plot_el) {
            plot_el.attr('aria-hidden', 'true');
          }

          if (slider_el) {
            slider_el.attr('aria-hidden', 'true');
          }

          if (plot && slider_el) {
            slider_el.width(plot.width());
            slider_el.css("display", "block");
          } else if (slider_el) {
            slider_el.css("width", "100%");
          }
        }

        // Slider change should update text input values.
        var parent = $(thisContext).parent();
        var form = $(parent).closest(".limit_content").find("form.range_limit");
        $(parent).closest(".limit_content").find(".profile .range").on("slide", function(event, ui) {
          var values = $(event.target).data("slider").getValue();
          form.find("input.range_begin").val(values[0]);
          form.find("input.range_end").val(values[1]);
        });
      }

      begin_el.val(min);
      end_el.val(max);

      begin_el.on('input', function() {
        var val = BlacklightRangeLimit.parseNum(this.value);
        if (isNaN(val) || val < min) {
          //for weird data, set slider at min
          val = min;
        }
        var values = placeholder_input.data("slider").getValue();
        values[0] = val;
        placeholder_input.slider("setValue", values);
      });

      end_el.on('input', function() {
        var val = BlacklightRangeLimit.parseNum(this.value);
        if (isNaN(val) || val > max) {
          //weird entry, set slider to max
          val = max;
        }
        var values = placeholder_input.data("slider").getValue();
        values[1] = val;
        placeholder_input.slider("setValue", values);
      });

      begin_el.change(function() {
        var val1 = BlacklightRangeLimit.parseNum(begin_el.val());
        var val2 = BlacklightRangeLimit.parseNum(end_el.val());

        if (val2 < val1) {
          begin_el.val(val2);
          end_el.val(val1);
        }
      });

      end_el.change(function() {
        var val1 = BlacklightRangeLimit.parseNum(begin_el.val());
        var val2 = BlacklightRangeLimit.parseNum(end_el.val());

        if (val2 < val1) {
          begin_el.val(val2);
          end_el.val(val1);
        }
      });
    };

  BlacklightRangeLimit.initialize = function() {
    // Support for Blacklight 7 and 8:
    const modalSelector = Blacklight.modal?.modalSelector || Blacklight.Modal.modalSelector; 

    RangeLimitDistroFacet.initialize(modalSelector);
    RangeLimitSlider.initialize(modalSelector);
  };

  return BlacklightRangeLimit;

}));
//# sourceMappingURL=blacklight_range_limit.umd.js.map
