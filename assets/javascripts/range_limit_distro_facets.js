jQuery(document).ready(function($) {
  // Add AJAX fetched range facets if needed
  $(".range_limit .profile .distribution a.load_distribution").each(function() {
      var container = $(this).parent('div.distribution');
  
      $(container).load($(this).attr('href'), function(response, status) {
          if (status == "success") {
  
            $(container).parent().parent().show();
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
            series_data.push( [to, avg] );
            
            x_ticks.push(from);
            
            pointer_lookup.push({from: from, to: to, count: count, label: $(this).find(".facet_select").text() });
        });
        x_ticks.push(parseInt($(container).find("ul li:last-child span.to").text()));


        var plot;
        try {
          plot = $.plot($(container), [series_data],{ 
            yaxis: { ticks: [] },
            //xaxis: { ticks: x_ticks },
            series: { lines: { fill: true, steps: true }},
            grid: {clickable: true, hoverable: true, autoHighlight: false},
            selection: {mode: "x"}
          });
        }
        catch(err) {
          alert(err); 
        }
        find_segment_for = function_for_find_segment(pointer_lookup);
        $(container).bind("plothover", function (event, pos, item) {
            segment = find_segment_for(pos.x);
            showTooltip(pos.pageX, pos.pageY, '<span class="label">' + segment.label + ':</span> <span class="count">' + segment.count + ' documents</span>');            
        });
        $(container).bind("mouseout", function() {
          $("#range_limit_tooltip").fadeOut(200);
        });
        $(container).bind("plotclick", function (event, pos, item) {
            if ( plot.getSelection() == null) {
              segment = find_segment_for(pos.x);
              plot.setSelection( {xaxis: { from:segment.from, to:segment.to}});
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
          slider_container.slider("values", 1, to);
        });
        
        var form = //$(container).closest(".limit_content").find("form.range_limit");
        //form.find("input.range_begin").change(function () {
        //   alert("changed"); 
        //});
        $(container).closest(".limit_content").find(".profile .range").bind("slide", function(event, ui) {
           plot.setSelection( {xaxis: { from:ui.values[0], to:ui.values[1]}}, true);
        });
       
        plot.setSelection( {xaxis: { from:min, to:max}}  );  
        
      }
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
    
     var tooltip = $('<div id="range_limit_tooltip"></div>').css( {
            position: 'absolute',
            display: 'none'           
        }).appendTo("body");
    function showTooltip(x, y, contents) {
      var tooltip = $("#range_limit_tooltip");

      tooltip.css('left', x+5);      
      tooltip.css('top', y-30);
      tooltip.html(contents);
      tooltip.fadeIn(200);                       
    }

});
