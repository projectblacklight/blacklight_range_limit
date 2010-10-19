# Meant to be applied on top of a controller that implements
# Blacklight::SolrHelper. Will inject range limiting behaviors
# to solr parameters creation. 
module BlacklightRangeLimit::ControllerOverride
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

    # Remove all field faceting for efficiency, we won't be using it.
    solr_params.delete("facet.field")
    solr_params.delete("facet.field".to_sym)
    
    add_range_segments_to_solr!(solr_params, solr_field, start, finish )
    # We don't need any actual rows or facets, we're just going to look
    # at the facet.query's
    solr_params[:rows] = 0
    solr_params[:facets] = nil
    # Not really any good way to turn off facet.field's from the solr default,
    # no big deal it should be well-cached at this point.
    
    @response = Blacklight.solr.find( solr_params )

    if request.xhr?
      render(:partial => 'blacklight_range_limit/range_segments', :locals => {:solr_field => solr_field})
    else
      render(:partial => 'blacklight_range_limit/range_segments', :layout => true, :locals => {:solr_field => solr_field})
    end
  end
  
  def solr_search_params(extra_params)
    solr_params = super(extra_params)
    
    #Annoying thing where default behavior is to mix together
    #params from request and extra_params argument, so we
    #must do that too.
    req_params = params.merge( extra_params )

    all_range_config.each_pair do |solr_field, config|
      config = {} if config == true
      # If we have any range facets configured, we want to ask for
      # the stats component to get min/max.
    
      solr_params["stats"] = "true"
      solr_params["stats.field"] ||= []
      solr_params["stats.field"] << solr_field    
    
      hash =  req_params["range"] && req_params["range"][solr_field] ?
        req_params["range"][solr_field] :
        {}
        
      if !hash["missing"].blank?
        # missing specified in request params
        solr_params[:fq] ||= []
        solr_params[:fq] << "-#{solr_field}:[* TO *]"
        
      elsif !(hash["begin"].blank? && hash["end"].blank?)
        # specified in request params, begin and/or end, might just have one
        start = hash["begin"].blank? ? "*" : hash["begin"]
        finish = hash["end"].blank? ? "*" : hash["end"]

        solr_params[:fq] ||= []
        solr_params[:fq] << "#{solr_field}: [#{start} TO #{finish}]"
        
        if (config[:segments] != false && start != "*" && finish != "*")
          # Add in our calculated segments, can only do with both boundaries.
          add_range_segments_to_solr!(solr_params, solr_field, start.to_i, finish.to_i)
        end
        
      elsif (config[:segments] != false &&
             boundaries = config[:assumed_boundaries])
        # assumed_boundaries in config
        add_range_segments_to_solr!(solr_params, solr_field, boundaries[0], boundaries[1])
      end
    end
    
    return solr_params
  end

  # Returns range config hash for named solr field. Returns false
  # if not configured. Returns hash even if configured to 'true'
  # for consistency. 
  def range_config(solr_field)    
    config = all_range_config[solr_field] || false
    config = {} if config == true # normalize bool true to hash
    return config
  end
  # returns a hash of solr_field => config for all configured range
  # facets, or empty hash. 
  # Uses Blacklight.config, needs to be modified when
  # that changes to be controller-based. This is the only method
  # in this plugin that accesses Blacklight.config, single point
  # of contact. 
  def all_range_config
    Blacklight.config[:facet][:range] || {}
  end

end
