# Additional helper methods used by view templates inside this plugin. 
module RangeLimitHelper

  # type is 'begin' or 'end'
  def render_range_input(solr_field, type)
    type = type.to_s
    
    default = params["range"][solr_field][type] if params["range"] && params["range"][solr_field] && params["range"][solr_field][type]
    
    text_field_tag("range[#{solr_field}][#{type}]", default, :maxlength=>4, :class => "range_#{type}")
  end

  def should_show_limit(solr_field)
    # For now, just if there are any hits at all, will expand later
    # to if there is actually a range spread available.
    @response.total > 0
  end
  
end
