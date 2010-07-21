# Meant to be applied on top of a controller that implements
# Blacklight::SolrHelper. Will inject range limiting behaviors
# to solr parameters creation. 
module BlacklightRangeLimit::SolrHelperOverride
  include SegmentCalculation
  def self.included(some_class)
    some_class.helper_method :range_config
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
    add_range_segments_to_solr!(solr_params, solr_field, start, finish )
    # We don't need any actual rows or facets, we're just going to look
    # at the facet.query's
    solr_params[:rows] = 0
    solr_params[:facets] = nil
    # Not really any good way to turn off facet.field's from the solr default,
    # no big deal it should be well-cached at this point.
    
    @response = Blacklight.solr.find( solr_params )

    if request.xhr?
      render(:partial => 'blacklight_range_limit/range_facets', :locals => {:solr_field => solr_field})
    else
      render(:partial => 'blacklight_range_limit/range_facets', :layout => true, :locals => {:solr_field => solr_field})
    end
  end
  
  def solr_search_params(extra_params)
    solr_params = super(extra_params)

    # If we have any range facets configured, we want to ask for
    # the stats component to get min/max.
    range_config.keys.each do |solr_field|
      solr_params["stats"] = "true"
      solr_params["stats.field"] ||= []
      solr_params["stats.field"] << solr_field
    end
    
    
    #Annoying thing where default behavior is to mix together
    #params from request and extra_params argument, so we
    #must do that too.
    req_params = params.merge( extra_params )
    
    unless req_params["range"].blank?      
      req_params["range"].each_pair do |solr_field, hash|
        missing = !hash["missing"].blank?
        if missing
          solr_params[:fq] ||= []
          solr_params[:fq] = "-#{solr_field}:[* TO *]"
        else          
          start = hash["begin"].blank? ? "*" : hash["begin"]
          finish = hash["end"].blank? ? "*" : hash["end"]
  
          next if start == "*" && finish == "*"
  
          solr_params[:fq] ||= []
          solr_params[:fq] << "#{solr_field}: [#{start} TO #{finish}]"

          # Add in our calculated segments
          add_range_segments_to_solr!(solr_params, solr_field, start.to_i, finish.to_i)
        end
      end
    end
    return solr_params
  end

  # Gets from Blacklight singleton object now, this method is a single
  # point of interface with Blacklight singleton, so if all config
  # is refactored to be controller based, we only have one place
  # to change. 
  def range_config
    Blacklight.config[:facet][:range]
  end

  protected

  

end
