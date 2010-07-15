# Meant to be applied on top of a controller that implements
# Blacklight::SolrHelper. Will inject range limiting behaviors
# to solr parameters creation. 
module BlacklightRangeLimit::SolrHelperOverride
  
  def solr_search_params(extra_params)
    solr_params = super(extra_params)

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
  
end
