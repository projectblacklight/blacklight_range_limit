# Meant to be applied on top of a controller that implements
# Blacklight::SolrHelper. Will inject range limiting behaviors
# to solr parameters creation. 
module BlacklightRangeLimit::SolrHelperOverride
  def self.included(some_class)
    some_class.helper_method :range_config
  end
  
  def solr_search_params(extra_params)
    solr_params = super(extra_params)

    # If we have any range facets configured, we want to ask for
    # the stats component to get min/max.
    #range_config.keys.each do |solr_field|
    #  solr_params["stats"] = "true"
    #  solr_params["stats_field"] ||= []
    #  solr_params["stats_field"] << solr_field
    #end
    
    
    #Annoying thing where default behavior is to mix together
    #params from request and extra_params argument, so we
    #must do that too.
    req_params = params.merge( extra_params )
    
    unless req_params["range"].blank?      
      req_params["range"].each_pair do |solr_field, hash|
        start = hash["begin"].blank? ? "*" : hash["begin"]
        finish = hash["end"].blank? ? "*" : hash["end"]

        next if start == "*" && finish == "*"

        solr_params[:fq] ||= []
        solr_params[:fq] << "#{solr_field}: [#{start} TO #{finish}]"
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
  
end
