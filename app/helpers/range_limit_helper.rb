module RangeLimitHelper
  extend Deprecation


  # Show the limit area if:
  # 1) we have a limit already set
  # OR
  # 2) stats show max > min, OR
  # 3) count > 0 if no stats available.
  def should_show_limit(solr_field)
    presenter = range_facet_field_presenter(solr_field)

    presenter.selected_range ||
      (presenter.max && presenter.min && presenter.max > presenter.min) ||
      @response.total.positive?
  end

  def remove_range_param(solr_field, my_params = params)
    Blacklight::SearchState.new(my_params.except(:page), blacklight_config).filter(solr_field).remove(0..0)
  end

  private

  def range_facet_field_presenter(key)
    facet_config = blacklight_config.facet_fields[key] || Blacklight::Configuration::FacetField.new(key: key, **BlacklightRangeLimit.default_range_config)
    facet_field_presenter(facet_config, Blacklight::Solr::Response::Facets::FacetField.new(key, [], response: @response))
  end

  def range_form_component(key)
    presenter = range_facet_field_presenter(key)

    BlacklightRangeLimit::RangeFormComponent.new(facet_field: presenter)
  end
end
