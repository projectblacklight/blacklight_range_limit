# BlacklightRangeLimit
require 'deprecation'

module BlacklightRangeLimit
  extend Deprecation

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
    form: 'range_limit subsection form-inline mt-3',
    submit: 'submit btn btn-secondary'
  }

  # Add element to array only if it's not already there
  def self.safe_arr_add(array, element)
    Deprecation.warn(BlacklightRangeLimit, 'BlacklightRangeLimit.safe_arr_add is deprecated without replacement')
    array << element unless array.include?(element)
  end

  def self.range_config(blacklight_config, solr_field)
    Deprecation.warn(BlacklightRangeLimit, 'BlacklightRangeLimit.range_config is deprecated without replacement')
    field = blacklight_config.facet_fields[solr_field.to_s]

    return false unless field&.range

    if field.range == true
      default_range_config
    else
      field.range.merge(partial: field.partial)
    end
  end

  def self.default_range_config
    {
      range: true,
      range_config: {
        num_segments: 10,
        chart_js: true,
        segments: true,
        assumed_boundaries: nil,
        maxlength: nil,
        input_label_range_begin: nil,
        input_label_range_end: nil
      },
      filter_class: BlacklightRangeLimit::FilterField,
      presenter: BlacklightRangeLimit::FacetFieldPresenter,
      item_presenter: BlacklightRangeLimit::FacetItemPresenter,
      component: BlacklightRangeLimit::RangeFacetComponent
    }
  end
end
