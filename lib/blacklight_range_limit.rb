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

  # Extract a year integer from a Solr date value.
  # Handles ISO-8601 dates like "1998-01-01T00:00:00Z", truncated dates like "1998",
  # and numeric values (integers/floats).
  # Returns an integer year or nil if the value cannot be parsed.
  def self.year_from_solr_date(value)
    return nil if value.nil?

    case value
    when Integer
      value
    when Float
      value.to_i
    when String
      value = value.strip
      return nil if value.empty?

      # Match optional negative sign followed by digits at the start (the year portion)
      ::Regexp.last_match(1).to_i if value =~ /\A(-?\d+)/
    end
  end

  # Convert a year integer to a Solr-compatible date string for use with DateRangeField.
  # DateRangeField accepts truncated dates like "1998" to mean the entire year.
  def self.year_to_solr_date(year)
    year.to_s
  end

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
        min_value: 0,
        max_value: 9999
      },
      filter_class: BlacklightRangeLimit::FilterField,
      presenter: BlacklightRangeLimit::FacetFieldPresenter,
      item_presenter: BlacklightRangeLimit::FacetItemPresenter,
      component: BlacklightRangeLimit::RangeFacetComponent
    }
  end
end
