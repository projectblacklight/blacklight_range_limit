# Additional helper methods used by view templates inside this plugin. 
module RangeLimitHelper

  # type is 'begin' or 'end'
  def render_range_input(solr_field, type)
    type = type.to_s
    
    default = params["range"][solr_field][type] if params["range"] && params["range"][solr_field] && params["range"][solr_field][type]
    
    text_field_tag("range[#{solr_field}][#{type}]", default, :maxlength=>4, :class => "range_#{type}")
  end

  # type is 'min' or 'max'
  # Returns smallest and largest value in current result set, if available
  # from stats component response. 
  def range_results_endpoint(solr_field, type)
    stats = stats_for_field(solr_field)
        
    return nil unless stats
    # StatsComponent returns weird min/max when there are in
    # fact no values
    return nil if @response.total == stats["missing"]

    return stats[type].to_s.gsub(/\.0+/, '')
  end

  def range_display(solr_field, my_params = params)
    return "" unless my_params[:range] && my_params[:range][solr_field]

    hash = my_params[:range][solr_field]
    
    if hash["missing"]
      return BlacklightRangeLimit.labels[:missing]
    elsif hash["begin"] || hash["end"]
      if hash["begin"] == hash["end"]
        return "<span class='single'>#{h(hash["begin"])}</span>".html_safe
      else
        return "<span class='from'>#{h(hash['begin'])}</span> to <span class='to'>#{h(hash['end'])}</span>".html_safe
      end
    end

    return ""
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

  def add_range_missing(solr_field, my_params = params)
    my_params = Marshal.load(Marshal.dump(my_params))
    my_params["range"] ||= {}
    my_params["range"][solr_field] ||= {}
    my_params["range"][solr_field]["missing"] = "true"

    # Need to ensure there's a search_field to trick Blacklight
    # into displaying results, not placeholder page. Kind of hacky,
    # but works for now.
    my_params["search_field"] ||= "dummy_range"

    my_params
  end

  def add_range(solr_field, from, to, my_params = params)
    my_params = Marshal.load(Marshal.dump(my_params))
    my_params["range"] ||= {}
    my_params["range"][solr_field] ||= {}

    my_params["range"][solr_field]["begin"] = from
    my_params["range"][solr_field]["end"] = to
    my_params["range"][solr_field].delete("missing")
    
    return my_params
  end
  
end
