jQuery(document).ready(function($) {
    
    // Takes a div holding a ul of distribution segments produced by 
    // blacklight_range_limit/_range_facets and makes it into
    // a flot area chart. 
    function areaChart(container) {      
      //flot loaded?
      if ($.plot ) {
        
        // Grab the data from the ul div
        var series_data = new Array();
        var count_lookup = new Array();
        var x_ticks = new Array();
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
            
            
        });
        x_ticks.push(parseInt($(container).find("ul li:last-child span.to").text()));


        /*
        try {
          $.plot($(container), [series_data],{ 
            yaxis: { ticks: [] },
            xaxis: { ticks: x_ticks },
            series: { lines: { fill: true, steps: true }},
            grid: {clickable: true, hoverable: true, autoHighlight: false}
          });
        }
        catch(err) {
          alert(err); 
        }
        $(container).bind("plothover", function (event, pos, item) {
           x_ticks  
           pos.x 
        });
        */
      }
    }
    
    
$(".range_limit .profile .range").each(function() {
   var range_element = $(this);
    
   var min = $(this).find(".min").first().text();
   var max = $(this).find(".max").first().text();

   if (min && max) {
     min = parseInt(min);
     max = parseInt(max);
          
     $(this).contents().wrapAll('<div style="display:none" />');
     
     var range_element = $(this);
     var form = $(range_element).closest(".range_limit").find("form.range_limit");
     var begin_el = form.find("input.range_begin");
     var end_el = form.find("input.range_end");
     
     $(this).slider({
         range: true,
         min: min,
				 max: max,
				 values: [min, max],
				 slide: function(event, ui) {
            begin_el.val(ui.values[0]);
            end_el.val(ui.values[1]);
					}
			});

      
      begin_el.val(min);
      end_el.val(max);
      
      begin_el.change( function() {
         var val = parseInt($(this).val());
         if ( (!isNaN(val))  && val >= min) {
           range_element.slider("values", 0, val);
         }
      });
      
      end_el.change( function() {
         var val = parseInt($(this).val());
         if ( (!isNaN(val)) && val <= max) {
           range_element.slider("values", 1, val);
         }
      });
            
   }
});

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

});
