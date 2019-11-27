# Additional helper methods used by view templates inside this plugin.
module RangeLimitHelper
  def range_limit_url(options = {})
    main_app.url_for(search_state.to_h.merge(action: 'range_limit').merge(options))
  end

  def range_limit_panel_url(options = {})
    main_app.url_for(search_state.to_h.merge(action: 'range_limit_panel').merge(options))
  end

  # type is 'begin' or 'end'
  def render_range_input(solr_field, type, input_label = nil, maxlength=4)
    type = type.to_s

    default = params["range"][solr_field][type] if params["range"] && params["range"][solr_field] && params["range"][solr_field][type]

    html = label_tag("range[#{solr_field}][#{type}]", input_label, class: 'sr-only') if input_label.present?
    html ||= ''.html_safe
    html += text_field_tag("range[#{solr_field}][#{type}]", default, :maxlength=>maxlength, :class => "form-control range_#{type}")
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
      return t('blacklight.range_limit.missing')
    elsif hash["begin"] || hash["end"]
      if hash["begin"] == hash["end"]
        return t('blacklight.range_limit.single_html', begin: h(hash['begin']))
      else
        return t('blacklight.range_limit.range_html', begin: h(hash['begin']), end: h(hash['end']))
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

  def stats_for_field?(solr_field)
    stats_for_field(solr_field).present?
  end

  def add_range_missing(solr_field, my_params = params)
    my_params = Blacklight::SearchState.new(my_params.except(:page), blacklight_config).to_h
    my_params["range"] ||= {}
    my_params["range"][solr_field] ||= {}
    my_params["range"][solr_field]["missing"] = "true"

    my_params
  end

  def add_range(solr_field, from, to, my_params = params)
    my_params = Blacklight::SearchState.new(my_params.except(:page), blacklight_config).to_h
    my_params["range"] ||= {}
    my_params["range"][solr_field] ||= {}

    my_params["range"][solr_field]["begin"] = from
    my_params["range"][solr_field]["end"] = to
    my_params["range"][solr_field].delete("missing")

    # eliminate temporary range status params that were just
    # for looking things up
    my_params.delete("range_field")
    my_params.delete("range_start")
    my_params.delete("range_end")

    return my_params
  end

  def has_selected_range_limit?(solr_field)
    params["range"] &&
    params["range"][solr_field] &&
    (
      params["range"][solr_field]["begin"].present? ||
      params["range"][solr_field]["end"].present? ||
      params["range"][solr_field]["missing"]
    )
  end

  def selected_missing_for_range_limit?(solr_field)
    params["range"] && params["range"][solr_field] && params["range"][solr_field]["missing"]
  end

end
