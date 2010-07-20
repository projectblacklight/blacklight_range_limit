jQuery(document).ready(function($) {
    
      
   

    
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
				 max: max+1,
				 values: [min, max+1],
				 slide: function(event, ui) {
            begin_el.val(ui.values[0]);
            
            end_el.val(Math.max(ui.values[1]-1, ui.values[0]));
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
           range_element.slider("values", 1, val+1);
         }
      });
            
   }
});

});
