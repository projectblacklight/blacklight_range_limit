(function (global, factory) {
  typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
  typeof define === 'function' && define.amd ? define(factory) :
  (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.BlacklightRangeLimit = factory());
})(this, (function () { 'use strict';

  /**
   * BlacklightRangeLimit module setup.
   */

  const BlacklightRangeLimit = function (options) {
    this.options = options || {};
  };

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

  BlacklightRangeLimit.modalObserverConfig = {
    attributes: true,
  };

  BlacklightRangeLimit.initSliderModalObserver = function(modalSelector) {
    // Use a mutation observer to detect when the modal dialog is open
    const modalObserver = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        if (mutation.attributeName !== 'open') {return;}
        if (mutation.target.hasAttribute('open')) {
          $(modalSelector).find(".range_limit .profile .range.slider_js").each(function() {
            BlacklightRangeLimit.buildSlider(this);
          });
        }
      });
    });
    modalObserver.observe(document.querySelector(modalSelector), BlacklightRangeLimit.modalObserverConfig);
  };

  BlacklightRangeLimit.initPlotModalObserver = function(modalSelector) {
    // Use a mutation observer to detect when the modal dialog is open
    const modalObserver = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        if (mutation.attributeName !== 'open') {return;}
        if (mutation.target.hasAttribute('open')) {
          $(modalSelector).find(".range_limit .profile .distribution.chart_js ul").each(function() {
            BlacklightRangeLimit.turnIntoPlot($(this).parent());
          });

          // Case when there is no currently selected range
          BlacklightRangeLimit.checkForNeededFacetsToFetch();
        }
      });
    });
    modalObserver.observe(document.querySelector(modalSelector), BlacklightRangeLimit.modalObserverConfig);
  };

  // second arg, if provided, is a number of ms we're willing to

  BlacklightRangeLimit.turnIntoPlot = function turnIntoPlot(container, wait_for_visible) {
    // flot can only render in a a div with a defined width.
    // for instance, a hidden div can't generally be rendered in (although if you set
    // an explicit width on it, it might work)
    //
    // We'll count on later code that catch bootstrap collapse open to render
    // on show, for currently hidden divs.

    // for some reason width sometimes return negative, not sure
    // why but it's some kind of hidden.
    if (container.width() > 0) {
      var height = container.width() * BlacklightRangeLimit.display_ratio;

      // Need an explicit height to make flot happy.
      container.height( height );

      BlacklightRangeLimit.areaChart($(container));

      $(container).trigger(BlacklightRangeLimit.redrawnEvent);
    }
    else if (wait_for_visible > 0) {
      setTimeout(function() {
        BlacklightRangeLimit.turnIntoPlot(container, wait_for_visible - 50);
      }, 50);
    }
  };

  BlacklightRangeLimit.parseSegment = function parseSegment(el) {
    if ($(el).find("span.single").first().data('blrlSingle')) {
      var val = BlacklightRangeLimit.parseNum($(el).find("span.single").first().data('blrlSingle'));

      return [val, val];
    } else {
      var from = BlacklightRangeLimit.parseNum($(el).find("span.from").first().data('blrlBegin'));
      var to = BlacklightRangeLimit.parseNum($(el).find("span.to").first().data('blrlEnd'));

      return [from, to];
    }
  };

  // Takes a div holding a ul of distribution segments produced by
  // blacklight_range_limit/_range_facets and makes it into
  // a flot area chart.
  BlacklightRangeLimit.areaChart = function areaChart(container) {
    //flot loaded? And canvas element supported.
    if ( BlacklightRangeLimit.domDependenciesMet()  ) {

      // Grab the data from the ul div
      var series_data = new Array();
      var pointer_lookup = new Array();
      var x_ticks = new Array();
      var min = BlacklightRangeLimit.parseSegment($(container).find("ul li:first-child").first())[0];
      var max = BlacklightRangeLimit.parseSegment($(container).find("ul li:last-child").first())[1];

      $(container).find("ul li").each(function() {
          var segment = BlacklightRangeLimit.parseSegment(this);
          var from = segment[0];
          var to = segment[1];

          var count = BlacklightRangeLimit.parseNum($(this).find("span.facet-count,span.count").text());
          var avg = (count / (to - from + 1));

          //We use the avg as the y-coord, to make the area of each
          //segment proportional to how many documents it holds.
          series_data.push( [from, avg ] );
          series_data.push( [to+1, avg] );

          x_ticks.push(from);

          pointer_lookup.push({'from': from, 'to': to, 'count': count, 'label': $(this).find(".facet-select,.facet_select").html() });
      });

      x_ticks.push( max + 1 );

      var plot;
      var config = $(container).closest('.blrl-plot-config').data('plot-config') || $(container).closest('.facet-limit').data('plot-config') || {};

      try {
        plot = $.plot($(container), [series_data],
            $.extend(true, config, {
            yaxis: {  ticks: [], min: 0, autoscaleMargin: 0.1},
          //xaxis: { ticks: x_ticks },
          xaxis: { tickDecimals: 0 }, // force integer ticks
          series: { lines: { fill: true, steps: true }},
          grid: {clickable: true, hoverable: true, autoHighlight: false, margin: { left: 0, right: 0 }},
          selection: {mode: "x"}
        }));
      }
      catch(err) {
        alert(err);
      }

      var find_segment_for = BlacklightRangeLimit.function_for_find_segment(pointer_lookup);
      var last_segment = null;
      $(container).tooltip({'html': true, 'placement': 'bottom', 'trigger': 'manual', 'delay': { show: 0, hide: 100}});

      $(container).bind("plothover", function (event, pos, item) {
        var segment = find_segment_for(pos.x);

        if(segment != last_segment) {
          var title = find_segment_for(pos.x).label  + ' (' + BlacklightRangeLimit.parseNum(segment.count) + ')';
          $(container).attr("title", title).tooltip("_fixTitle").tooltip("show");

          last_segment  = segment;
         }
      });

      $(container).bind("mouseout", function() {
        last_segment = null;
        $(container).tooltip('hide');
      });
      $(container).bind("plotclick", function (event, pos, item) {
          if ( plot.getSelection() == null) {
            segment = find_segment_for(pos.x);
            plot.setSelection(BlacklightRangeLimit.normalized_selection(segment.from, segment.to));
          }
      });
      $(container).bind("plotselected plotselecting", function(event, ranges) {
        if (ranges != null ) {
          var from = Math.floor(ranges.xaxis.from);
          var to = Math.floor(ranges.xaxis.to);

          var form = $(container).closest(".limit_content").find("form.range_limit");
          form.find("input.range_begin").val(from);
          form.find("input.range_end").val(to);

          var slider_placeholder = $(container).closest(".limit_content").find("[data-slider-placeholder]");
          if (slider_placeholder) {
            slider_placeholder.slider("setValue", [from, to]);
          }
        }
      });

      var form = $(container).closest(".limit_content").find("form.range_limit");
      form.find("input.range_begin, input.range_end").on('input', function () {
        plot.setSelection( BlacklightRangeLimit.form_selection(form, min, max), true );
      });
      $(container).closest(".limit_content").find(".profile .range").on("slide", function(event, ui) {
        var values = $(event.target).data("slider").getValue();
        form.find("input.range_begin").val(values[0]);
        form.find("input.range_end").val(values[1]);
        plot.setSelection(BlacklightRangeLimit.normalized_selection(values[0], Math.max(values[0], values[1])), true);
      });

      // initially entirely selected, to match slider
      plot.setSelection(BlacklightRangeLimit.normalized_selection(min, max));
    }
  };

  // after a collapsible facet contents is fully shown,
  // resize the flot chart to current conditions. This way, if you change
  // browser window size, you can get chart resized to fit by closing and opening
  // again, if needed.
  BlacklightRangeLimit.redrawPlot = function redrawPlot(container) {
    if (container && container.width() > 0) {
      // resize the container's height, since width may have changed.
      container.height( container.width() * BlacklightRangeLimit.display_ratio  );

      // redraw the chart.
      var plot = container.data("plot");
      if (plot) {
        // how to redraw after possible resize?
        // Cribbed from https://github.com/flot/flot/blob/master/jquery.flot.resize.js
        plot.resize();
        plot.setupGrid();
        plot.draw();
        // plus trigger redraw of the selection, which otherwise ain't always right
        // we'll trigger a fake event on one of the boxes
        var form = $(container).closest(".limit_content").find("form.range_limit");
        form.find("input.range_begin").trigger("change");

        // send our custom event to trigger redraw of slider
        $(container).trigger(BlacklightRangeLimit.redrawnEvent);
      }
    }
  };

  /**
   * Closure functions in this file are mainly concerned with initializing, resizing, and updating
   * range limit functionality based off of page load, facet opening, page resizing, and otherwise
   * events.
   */

  BlacklightRangeLimit.initializeDistroFacets = function(modalSelector) {
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

    // For Blacklight version < 8, when loaded in a modal
    $(modalSelector).on('shown.bs.modal', function() {
      $(this).find(".range_limit .profile .distribution.chart_js ul").each(function() {
        BlacklightRangeLimit.turnIntoPlot($(this).parent());
      });

      // Case when there is no currently selected range
      BlacklightRangeLimit.checkForNeededFacetsToFetch();
    });

    // Use a mutation observer to detect when the HTML dialog is open
    BlacklightRangeLimit.initPlotModalObserver(modalSelector);

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
  };

  // for Blacklight.onLoad:

  BlacklightRangeLimit.initializeSlider = function(modalSelector) {

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
    BlacklightRangeLimit.initSliderModalObserver(modalSelector);

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

  BlacklightRangeLimit.initialize = function(modalSelector) {
    BlacklightRangeLimit.initializeDistroFacets(modalSelector);
    BlacklightRangeLimit.initializeSlider(modalSelector);
  };

  return BlacklightRangeLimit;

}));
//# sourceMappingURL=blacklight_range_limit.umd.js.map
