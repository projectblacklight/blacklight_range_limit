# Meant to be applied on top of a controller that implements
# Blacklight::SolrHelper. Will inject range limiting behaviors
# to solr parameters creation. 
require 'blacklight_range_limit/segment_calculation'
module BlacklightRangeLimit
  module ControllerOverride
    include SegmentCalculation
    extend ActiveSupport::Concern
  
    included do
      self.search_params_logic += [:add_range_limit_params]
      
      if self.respond_to? :search_params_logic
        # Parse app URL params used for adv searches 
        self.search_params_logic += [:add_range_limit_params]
      end

      if self.blacklight_config.search_builder_class and !self.blacklight_config.search_builder_class.include?(BlacklightRangeLimit::SearchBuilder )
        self.blacklight_config.search_builder_class.send(:include,BlacklightRangeLimit::SearchBuilder)
      end
            

      helper_method :range_config
  
      
      
      unless BlacklightRangeLimit.omit_inject[:view_helpers]
        helper BlacklightRangeLimit::ViewHelperOverride
        helper RangeLimitHelper
      end
    end
  
    # Action method of our own!
    # Delivers a _partial_ that's a display of a single fields range facets.
    # Used when we need a second Solr query to get range facets, after the
    # first found min/max from result set. 
    def range_limit
      query_params = search_builder.append(:get_range_limit_data).with(params).query(rows: 9, facets: nil)

      @response = repository.search(query_params)

      render('blacklight_range_limit/range_segments', locals: {solr_field: params[:range_field]}, layout: !request.xhr?)
    end

  end
end
