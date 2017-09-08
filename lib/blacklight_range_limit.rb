# BlacklightRangeLimit

module BlacklightRangeLimit
  require 'blacklight_range_limit/range_limit_builder'
  require 'blacklight_range_limit/controller_override'
  require 'blacklight_range_limit/view_helper_override'

  require 'blacklight_range_limit/version'
  require 'blacklight_range_limit/engine'

  autoload :Routes, 'blacklight_range_limit/routes'

  # Raised when an invalid range is encountered
  class InvalidRange < TypeError; end

  mattr_accessor :labels, :classes
  self.labels = {
    :missing => "Unknown"
  }
  self.classes = {
    form: 'range_limit subsection form-inline',
    submit: 'submit btn btn-default'
  }

  # Add element to array only if it's not already there
  def self.safe_arr_add(array, element)
    array << element unless array.include?(element)
  end

  # Convenience method for returning range config hash from
  # blacklight config, for a specific solr field, in a normalized
  # way.
  #
  # Returns false if range limiting not configured.
  # Returns hash even if configured to 'true'
  # for consistency.
  def self.range_config(blacklight_config, solr_field)
    field = blacklight_config.facet_fields[solr_field.to_s]

    return false unless field.range

    config = field.range
    config = { partial: field.partial } if config === true

    config
  end
end
