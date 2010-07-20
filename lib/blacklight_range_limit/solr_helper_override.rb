# Meant to be applied on top of a controller that implements
# Blacklight::SolrHelper. Will inject range limiting behaviors
# to solr parameters creation. 
module BlacklightRangeLimit::SolrHelperOverride
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
    
    solr_params = solr_search_params(params).merge( add_range_segments_to_solr(solr_field, start, finish ) )
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
  # Calculates segment facets within a given start and end on a given
  # field, returns request params to be added on to what's sent to
  # solr to get the calculated facet segments.
  # Assumes solr_field is an integer, as range endpoint will be found
  # by subtracting one from subsequent boundary. 
  def add_range_segments_to_solr(solr_field, min, max)    
    extra_solr_params = {}

    #return extra_solr_params if (max - min) == 0 
    
    extra_solr_params[:"facet.query"] = []
    
    boundaries = boundaries_for_range_facets(min, max, 6) # 4.818
    # Now make the boundaries into actual filter.queries.
    0.upto(boundaries.length - 2) do |index|
      first = boundaries[index]
      last = (index == (boundaries.length() - 2)) ? (boundaries[index+1]) : (boundaries[index+1].to_i - 1)
    
      extra_solr_params[:"facet.query"] << "#{solr_field}:[#{first} TO #{last}]"
    end

    return extra_solr_params
  end

  # returns an array of 'boundaries' for producing approx num_div
  # segments between first and last.  The boundaries are 'nicefied'
  # to factors of 5 or 10, so exact number of segments may be more
  # or less than num_div. Algorithm copied from Flot. 
  def boundaries_for_range_facets(first, last, num_div)    
    #last += 1 # cause of the weird way we're doing this, this leads to better display. 
    # code cribbed from Flot auto tick calculating, but leaving out
    # some of Flot's options becuase it started to get confusing. 
    delta = (last - first).to_f / num_div
  
    # Don't know what most of these variables mean, just copying
    # from Flot. 
    dec = -1 * ( Math.log10(delta) ).floor
    magn = (10 ** (-1 * dec)).to_i
    norm = delta / magn; # norm is between 1.0 and 10.0

    size = 10
     if (norm < 1.5)
       size = 1
     elsif (norm < 3)
       size = 2;
       # special case for 2.5, requires an extra decimal
       if (norm > 2.25 ) 
         size = 2.5;
         dec = dec + 1
       end                
     elsif (norm < 7.5)
       size = 5
     end
    
     size = size * magn

     boundaries = []     

     start = floorInBase(first, size)
     i = 0
     v = Float::MAX
     prev = nil
     begin 
       prev = v
       v = start + i * size
       boundaries.push(v.to_i)
       i += 1
     end while ( v < last && v != prev)

     # That algorithm i don't entirely understand will sometimes
     # extend past our first and last, tighten it up and make sure
     # first and last are endpoints.
     boundaries.delete_if {|b| b <= first || b >= last}
     boundaries.unshift(first)
     boundaries.push(last)

     return boundaries
  end

  # Cribbed from Flot.  Round to nearby lower multiple of base
  def floorInBase(n, base) 
     return base * (n / base).floor
  end

  
  def round_nearest(number, nearest)
   (number/nearest.to_f).round * nearest
  end
end
