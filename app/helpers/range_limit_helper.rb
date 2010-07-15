# Additional helper methods used by view templates inside this plugin. 
module RangeLimitHelper

  # type is 'begin' or 'end'
  def render_range_input(solr_field, type)
    type = type.to_s
    
    default = params["range"][solr_field][type] if params["range"] && params["range"][solr_field] && params["range"][solr_field][type]
    
    text_field_tag("range[#{solr_field}][#{type}]", default, :maxlength=>4, :class => "range_#{type}")
  end

  # Show the limit area if:
  # 1) we have a limit already set
  # OR
  # 2) stats show max > min, OR
  # 3) count > 0 if no stats available. 
  def should_show_limit(solr_field)
    stats = stats_for_field(solr_field)
    
    (params["range"] && params["range"][solr_field]) ||
    (  stats &&
      stats["max"] > stats["min"]) ||
    ( !stats  && @response.total > 0 )
  end

  def stats_for_field(solr_field)
    @response["stats"]["stats_fields"][solr_field] if @response["stats"] && @response["stats"]["stats_fields"]
  end
  
end
