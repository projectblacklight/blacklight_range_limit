// second arg, if provided, is a number of ms we're willing to
// wait for the container to have width before giving up -- we'll
// set 50ms timers to check back until timeout is expired or the
// container is finally visible. The timeout is used when we catch
// bootstrap show event, but the animation hasn't barely begun yet -- but
// we don't want to wait until it's finished, we want to start rendering
// as soon as we can.

import BlacklightRangeLimit from 'range_limit_shared'

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
    container.height( height )

    BlacklightRangeLimit.areaChart($(container));

    $(container).trigger(BlacklightRangeLimit.redrawnEvent);
  }
  else if (wait_for_visible > 0) {
    setTimeout(function() {
      BlacklightRangeLimit.turnIntoPlot(container, wait_for_visible - 50);
    }, 50);
  }
}

BlacklightRangeLimit.parseSegment = function parseSegment(el) {
  if ($(el).find("span.single").first().data('blrlSingle')) {
    var val = BlacklightRangeLimit.parseNum($(el).find("span.single").first().data('blrlSingle'));

    return [val, val];
  } else {
    var from = BlacklightRangeLimit.parseNum($(el).find("span.from").first().data('blrlBegin'));
    var to = BlacklightRangeLimit.parseNum($(el).find("span.to").first().data('blrlEnd'));

    return [from, to];
  }
}

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
}

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
}
