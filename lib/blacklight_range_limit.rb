# BlacklightRangeLimit
module BlacklightRangeLimit
  require 'blacklight_range_limit/facet_field_config_override'
  require 'blacklight_range_limit/range_limit_builder'
  require 'blacklight_range_limit/controller_override'

  require 'blacklight_range_limit/version'
  require 'blacklight_range_limit/engine'

  autoload :Routes, 'blacklight_range_limit/routes'

  # Raised when an invalid range is encountered
  class InvalidRange < TypeError; end

  mattr_accessor :classes

  self.classes = {
    form: 'range_limit_form',
    submit: 'submit btn btn-sm btn-secondary'
  }

  def self.default_range_config
    {
      range: true,
      range_config: {
        num_segments: 10,
        chart_js: true,
        textual_facets: true,
        textual_facets_collapsible: true,
        show_missing_link: true,
        chart_segment_border_color: 'rgb(54, 162, 235)',
        chart_segment_bg_color: 'rgba(54, 162, 235, 0.5)',
        chart_aspect_ratio: 2,
        assumed_boundaries: nil,
        min_value: -2_147_483_648, # solr intfield min and max
        max_value: 2_147_483_648
      },
      filter_class: BlacklightRangeLimit::FilterField,
      presenter: BlacklightRangeLimit::FacetFieldPresenter,
      item_presenter: BlacklightRangeLimit::FacetItemPresenter,
      component: BlacklightRangeLimit::RangeFacetComponent
    }
  end
end
