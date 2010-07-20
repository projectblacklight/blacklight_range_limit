jQuery(document).ready(function($) {
  // Add AJAX fetched range facets if needed
  $(".range_limit .profile .distribution a.load_distribution").each(function() {
      var container = $(this).parent('div.distribution');
  
      $(container).load($(this).attr('href'), function(response, status) {
          if (status == "success") {
  
            $(container).parent().parent().show();
            
            // Flot needs explicit width and height, but we
            // can set em based on computed width. 
            $(container).width( $(container).width() );
            // half a golden rectangle, why not?
            $(container).height( $(container).width() / (1.618 * 2) );
            areaChart($(container));
            //$(container).parent().parent().hide();
  
          }
      });     
  });

          
   
     // Takes a div holding a ul of distribution segments produced by 
    // blacklight_range_limit/_range_facets and makes it into
    // a flot area chart. 
    function areaChart(container) {      
      //flot loaded?
      if ($.plot ) {
        
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
        try {
          plot = $.plot($(container), [series_data],{ 
              yaxis: {  ticks: [], min: 0, autoscaleMargin: 0.1},
            xaxis: { ticks: x_ticks },
            series: { lines: { fill: true, steps: true }},
            grid: {clickable: true, hoverable: true, autoHighlight: false},
            selection: {mode: "x"}
          });
        }
        catch(err) {
          alert(err); 
        }
        
        // Div initially hidden to show hover mouseover legend for
        // each segment. 
        $('<div class="subsection hover_legend ui-corner-all"></div>').css('display', 'none').insertAfter(container);
        
        find_segment_for = function_for_find_segment(pointer_lookup);
        $(container).bind("plothover", function (event, pos, item) {
            segment = find_segment_for(pos.x);
            showHoverLegend(container, '<span class="label">' + segment.label + '</span> <span class="count">(' + segment.count + ')</span>');            
        });
        $(container).bind("mouseout", function() {
          $(container).next(".hover_legend").fadeOut(200);
        });
        $(container).bind("plotclick", function (event, pos, item) {
            if ( plot.getSelection() == null) {
              segment = find_segment_for(pos.x);
              plot.setSelection( normalized_selection(segment.from, segment.to));
            }
        });
        $(container).bind("plotselected", function(event, ranges) {
          var from = Math.floor(ranges.xaxis.from) 
          var to = Math.floor(ranges.xaxis.to)
          
          var form = $(container).closest(".limit_content").find("form.range_limit");
          form.find("input.range_begin").val(from);
          form.find("input.range_end").val(to);
          
          var slider_container = $(container).closest(".limit_content").find(".profile .range");
          slider_container.slider("values", 0, from);
          slider_container.slider("values", 1, to+1);
        });
        
        var form = $(container).closest(".limit_content").find("form.range_limit");
        form.find("input.range_begin, input.range_end").change(function () {
           plot.setSelection( form_selection(form) , true );
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
    
    function form_selection(form) {
      var begin_val = parseInt($(form).find("input.range_begin").val());
      var end_val = parseInt($(form).find("input.range_end").val());
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
        
    function showHoverLegend(container, contents) {
      var el = $(container).next(".hover_legend");

      el.html(contents);                   
      el.fadeIn(200);
    }

});
