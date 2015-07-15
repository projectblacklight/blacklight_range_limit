# Meant to be applied on top of a controller that implements
# Blacklight::SolrHelper. Will inject range limiting behaviors
# to solr parameters creation. 
require 'blacklight_range_limit/segment_calculation'
module BlacklightRangeLimit
  module ControllerOverride
    include SegmentCalculation
    extend ActiveSupport::Concern
  
    included do
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
      solr_field = params[:range_field] # what field to fetch for
      start = params[:range_start].to_i
      finish = params[:range_end].to_i
      
      solr_params = solr_search_params(params)
  
      # Remove all field faceting for efficiency, we won't be using it.
      solr_params.delete("facet.field")
      solr_params.delete("facet.field".to_sym)
      
      add_range_segments_to_solr!(solr_params, solr_field, start, finish )
      # We don't need any actual rows or facets, we're just going to look
      # at the facet.query's
      solr_params[:rows] = 0
      solr_params[:facets] = nil
      solr_params[:qt] ||= blacklight_config.qt
      # Not really any good way to turn off facet.field's from the solr default,
      # no big deal it should be well-cached at this point.

      @response = Blacklight.default_index.connection.get( blacklight_config.solr_path, :params => solr_params )

      render('blacklight_range_limit/range_segments', :locals => {:solr_field => solr_field}, :layout => !request.xhr?)
    end
    
    # Returns range config hash for named solr field. Returns false
    # if not configured. Returns hash even if configured to 'true'
    # for consistency. 
    def range_config(solr_field)
      field = blacklight_config.facet_fields[solr_field.to_s]

      return false unless field.range

      config = field.range
      config = {} if config === true

      config
    end
  end
end
