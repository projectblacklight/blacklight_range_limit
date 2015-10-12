# BlacklightRangeLimit

module BlacklightRangeLimit
  require 'blacklight_range_limit/range_limit_builder'
  require 'blacklight_range_limit/controller_override'
  require 'blacklight_range_limit/view_helper_override'
  require 'blacklight_range_limit/route_sets'

  require 'blacklight_range_limit/version'
  require 'blacklight_range_limit/engine'

  mattr_accessor :labels
  self.labels = {
    :missing => "Unknown"
  }

  
  @omit_inject = {}
  def self.omit_inject=(value)
    value = Hash.new(true) if value == true
    @omit_inject = value      
  end
  def self.omit_inject ; @omit_inject ; end
  
  def self.inject!
    unless omit_inject[:controller_mixin]
        CatalogController.send(:include, BlacklightRangeLimit::ControllerOverride) unless Blacklight::Catalog.include?(BlacklightRangeLimit::ControllerOverride)
      end

      unless omit_inject[:view_helpers]
        SearchHistoryController.send(:helper, 
          BlacklightRangeLimit::ViewHelperOverride
        ) unless
          SearchHistoryController.helpers.is_a?( 
            BlacklightRangeLimit::ViewHelperOverride
          )
         
        SearchHistoryController.send(:helper, 
          RangeLimitHelper
        ) unless
          SearchHistoryController.helpers.is_a?( 
            RangeLimitHelper
          )
      end
      
      unless BlacklightRangeLimit.omit_inject[:routes]
        Blacklight::Routes.send(:include, BlacklightRangeLimit::RouteSets)
      end
  end

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
    config = {} if config === true

    config
  end
  
end
