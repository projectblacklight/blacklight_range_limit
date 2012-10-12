# Meant to be in a Controller, included in our ControllerOverride module.
module BlacklightRangeLimit
  module SegmentCalculation

    protected
    
    # Calculates segment facets within a given start and end on a given
    # field, returns request params to be added on to what's sent to
    # solr to get the calculated facet segments.
    # Assumes solr_field is an integer, as range endpoint will be found
    # by subtracting one from subsequent boundary.
    #
    # Changes solr_params passed in. 
    def add_range_segments_to_solr!(solr_params, solr_field, min, max)
      field_config = range_config(solr_field)    
    
      solr_params[:"facet.query"] ||= []
      
      boundaries = boundaries_for_range_facets(min, max, (field_config[:num_segments] || 10) ) 
      
      # Now make the boundaries into actual filter.queries.
      0.upto(boundaries.length - 2) do |index|
        first = boundaries[index]
        last =  boundaries[index+1].to_i - 1
      
        solr_params[:"facet.query"] << "#{solr_field}:[#{first} TO #{last}]"
      end
  
      return solr_params
    end
  
    # returns an array of 'boundaries' for producing approx num_div
    # segments between first and last.  The boundaries are 'nicefied'
    # to factors of 5 or 10, so exact number of segments may be more
    # or less than num_div. Algorithm copied from Flot.
    #
    # Because of arithmetic issues with creating boundaries that will
    # be turned into inclusive ranges, the FINAL boundary will be one
    # unit more than the actual end of the last range later computed. 
    def boundaries_for_range_facets(first, last, num_div)    
      # arithmetic issues require last to be one more than the actual
      # last value included in our inclusive range
      last += 1
    
      # code cribbed from Flot auto tick calculating, but leaving out
      # some of Flot's options becuase it started to get confusing. 
      delta = (last - first).to_f / num_div
    
      # Don't know what most of these variables mean, just copying
      # from Flot. 
      dec = -1 * ( Math.log10(delta) ).floor
      magn = (10 ** (-1 * dec)).to_f
      norm = (magn == 0) ? delta : (delta / magn) # norm is between 1.0 and 10.0
  
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
  
       # Can create dups for small ranges, tighten up
       boundaries.uniq!
       
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
    
  end
end
