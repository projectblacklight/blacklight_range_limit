jQuery(document).ready(function($) {
  // ratio of width to height for desired display, multiply width by this ratio
  // to get height. hard-coded in for now. 
  var display_ratio = 1/(1.618 * 2); // half a golden rectangle, why not


  // Facets already on the page? Turn em into a chart.
  $(".range_limit .profile .distribution.chart_js ul").each(function() {
      turnIntoPlot($(this).parent());
  });


  // Add AJAX fetched range facets if needed, and add a chart to em
  $(".range_limit .profile .distribution a.load_distribution").each(function() {
      var container = $(this).parent('div.distribution');

      $(container).load($(this).attr('href'), function(response, status) {
          if ($(container).hasClass("chart_js") && status == "success" ) {
            turnIntoPlot(container);
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
      turnIntoPlot(container, 1100);
    }
  });

  // after a collapsible facet contents is fully shown,
  // resize the flot chart to current conditions. This way, if you change
  // browser window size, you can get chart resized to fit by closing and opening
  // again, if needed. 
  $("body").on("shown.bs.collapse", function(event) {
    var container =  $(event.target).filter(".facet-content").find(".chart_js");

    if (container && container.width() > 0) {
      // resize the container's height, since width may have changed. 
      container.height( container.width() * display_ratio  );

      // redraw the chart. how to redraw after possible resize?
      // Cribbed from https://github.com/flot/flot/blob/master/jquery.flot.resize.js
      var plot = container.data("plot");
      if (plot) {        
        plot.resize();
        plot.setupGrid();
        plot.draw();
      }
    }    
  });

  // second arg, if provided, is a number of ms we're willing to
  // wait for the container to have width before giving up -- we'll
  // set 50ms timers to check back until timeout is expired or the
  // container is finally visible. The timeout is used when we catch
  // bootstrap show event, but the animation hasn't barely begun yet -- but
  // we don't want to wait until it's finished, we want to start rendering
  // as soon as we can. 
  function turnIntoPlot(container, wait_for_visible) {
    // flot can only render in a a div with a defined width.
    // for instance, a hidden div can't generally be rendered in (although if you set
    // an explicit width on it, it might work)
    //
    // We'll count on later code that catch bootstrap collapse open to render
    // on show, for currently hidden divs. 

    // for some reason width sometimes return negative, not sure
    // why but it's some kind of hidden. 
    if (container.width() > 0) {      
      var height = container.width() * display_ratio;
      
      // Need an explicit height to make flot happy.   
      container.height( height )
      
      areaChart($(container));
    }
    else if (wait_for_visible > 0) {
      setTimeout(function() {
        turnIntoPlot(container, wait_for_visible - 50);
      }, 50);
    }
  }

     // Takes a div holding a ul of distribution segments produced by
    // blacklight_range_limit/_range_facets and makes it into
    // a flot area chart.
    function areaChart(container) {
      //flot loaded? And canvas element supported.
      if (  domDependenciesMet()  ) {

        // Grab the data from the ul div
        var series_data = new Array();
        var pointer_lookup = new Array();
        var x_ticks = new Array();
        var min = parseInt($(container).find("ul li:first-child span.from").text());
        var max = parseInt($(container).find("ul li:last-child span.to").text());

        $(container).find("ul li").each(function() {
            var from = parseInt($(this).find("span.from").text());
            var to = parseInt($(this).find("span.to").text());
            var count = parseInt($(this).find("span.count").text());
            var avg = (count / (to - from + 1));


            //We use the avg as the y-coord, to make the area of each
            //segment proportional to how many documents it holds.
            series_data.push( [from, avg ] );
            series_data.push( [to+1, avg] );

            x_ticks.push(from);

            pointer_lookup.push({'from': from, 'to': to, 'count': count, 'label': $(this).find(".facet_select").text() });
        });
        var max_plus_one = parseInt($(container).find("ul li:last-child span.to").text())+1;
        x_ticks.push( max_plus_one );



        var plot;
        var config = $(container).closest('.facet_limit').data('plot-config') || {};

        try {
          plot = $.plot($(container), [series_data],
              $.extend(true, config, {
              yaxis: {  ticks: [], min: 0, autoscaleMargin: 0.1},
            //xaxis: { ticks: x_ticks },
            xaxis: { tickDecimals: 0 }, // force integer ticks
            series: { lines: { fill: true, steps: true }},
            grid: {clickable: true, hoverable: true, autoHighlight: false},
            selection: {mode: "x"}
          }));
        }
        catch(err) {
          alert(err);
        }

        find_segment_for = function_for_find_segment(pointer_lookup);
        var last_segment = null;

        $(container).bind("plothover", function (event, pos, item) {
            segment = find_segment_for(pos.x);

            if(segment != last_segment) {
            $('.distribution').tooltip('destroy');
            $('.distribution').tooltip({'title': function() { return find_segment_for(pos.x).label  + ' (' + segment.count + ')' }, 'placement': 'bottom', 'trigger': 'manual', 'delay': { show: 0, hide: 100}});

             last_segment  = segment;
           }
            $('.distribution').tooltip('show');

        });
        $(container).bind("mouseout", function() {
            $('.distribution').tooltip('hide');
        });
        $(container).bind("plotclick", function (event, pos, item) {
            if ( plot.getSelection() == null) {
              segment = find_segment_for(pos.x);
              plot.setSelection( normalized_selection(segment.from, segment.to));
            }
        });
        $(container).bind("plotselected plotselecting", function(event, ranges) {
            if (ranges != null ) {
              var from = Math.floor(ranges.xaxis.from);
              var to = Math.floor(ranges.xaxis.to);

              var form = $(container).closest(".limit_content").find("form.range_limit");
              form.find("input.range_begin").val(from);
              form.find("input.range_end").val(to);
              
              var slider_container = $(container).closest(".limit_content").find(".profile .range");
							$(document).ready(function() {
								slider_container.slider("values", 0, from);
	              slider_container.slider("values", 1, to+1);
							});
            }
        });

        var form = $(container).closest(".limit_content").find("form.range_limit");
        form.find("input.range_begin, input.range_end").change(function () {
           plot.setSelection( form_selection(form, min, max) , true );
        });
        $(container).closest(".limit_content").find(".profile .range").bind("slide", function(event, ui) {
           plot.setSelection( normalized_selection(ui.values[0], Math.max(ui.values[0], ui.values[1]-1)), true);
        });

        // initially entirely selected, to match slider
        plot.setSelection( {xaxis: { from:min, to:max+0.9999}}  );
        
        // try to make slider width/orientation match chart's
        var slider_container = $(container).closest(".limit_content").find(".profile .range");
        slider_container.width(plot.width());
        slider_container.css('margin-right', 'auto');
        slider_container.css('margin-left', 'auto');   
        // And set slider min/max to match charts, for sure
				$(document).ready(function() {
	        slider_container.slider("option", "min", min);
	        slider_container.slider("option", "max", max+1);					
				});

      }
    }


    // Send endpoint to endpoint+0.99999 to have display
    // more closely approximate limiting behavior esp
    // at small resolutions. (Since we search on whole numbers,
    // inclusive, but flot chart is decimal.)
    function normalized_selection(min, max) {
      max += 0.99999;

      return {xaxis: { 'from':min, 'to':max}}
    }

    function form_selection(form, min, max) {
      var begin_val = parseInt($(form).find("input.range_begin").val());
      if (isNaN(begin_val) || begin_val < min) {
        begin_val = min;
      }
      var end_val = parseInt($(form).find("input.range_end").val());
      if (isNaN(end_val) || end_val > max) {
        end_val = max;
      }

      return normalized_selection(begin_val, end_val);
    }

    function function_for_find_segment(pointer_lookup_arr) {
      return function(x_coord) {
        for (var i = pointer_lookup_arr.length-1 ; i >= 0 ; i--) {
          var hash = pointer_lookup_arr[i];
          if (x_coord >= hash.from)
            return hash;
        }
        return pointer_lookup_arr[0];
      };
    }
        
    // Check if Flot is loaded, and if browser has support for
    // canvas object, either natively or via IE excanvas. 
    function domDependenciesMet() {    
      var flotLoaded = (typeof $.plot != "undefined");
      var canvasAvailable = ((typeof(document.createElement('canvas').getContext) != "undefined") || (typeof  window.CanvasRenderingContext2D != 'undefined' || typeof G_vmlCanvasManager != 'undefined'));

      return (flotLoaded && canvasAvailable);
    }
});
