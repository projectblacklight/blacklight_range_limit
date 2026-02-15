# Used for building the search for the range_limit route
module BlacklightRangeLimit
  module RangeLimitSearchBuilderBehavior
    extend ActiveSupport::Concern

    included do
      # We need to swap out the add_range_limit_params search param filter,
      # and instead add in our fetch_specific_range_limit filter,
      # to fetch only the range limit segments for only specific
      # field (with start/end params) mentioned in query params
      # range_field, range_start, and range_end
      self.default_processor_chain += %i[fetch_specific_range_limit]
      self.default_processor_chain -= %i[add_range_limit_params]
    end

    # Another processing method, this one is NOT included in default processing chain,
    # it is specifically swapped in *instead of* add_range_limit_params for
    # certain ajax requests that only want to fetch range limit segments for
    # ONE field.
    #
    # It turns off facetting and sets rows to 0 as well, only results for
    # single specified field are needed.
    #
    # Specified field and parameters are specified in incoming parameters
    # range_field, range_start, range_end
    def fetch_specific_range_limit(solr_params)
      field_key = blacklight_params[:range_field] # what field to fetch for

      unless  blacklight_params[:range_start].present? && blacklight_params[:range_start].is_a?(String) &&
              blacklight_params[:range_end].present? && blacklight_params[:range_end].is_a?(String)
        raise BlacklightRangeLimit::InvalidRange
      end

      start = blacklight_params[:range_start].to_i
      finish = blacklight_params[:range_end].to_i

      add_range_segments_to_solr!(solr_params, field_key, start, finish)

      # Remove all field faceting for efficiency, we won't be using it.
      solr_params.delete('facet.field')
      solr_params.delete('facet.field'.to_sym)

      # We don't need any actual rows either
      solr_params[:rows] = 0

      solr_params
    rescue BlacklightRangeLimit::InvalidRange
      # This will make Rails return a 400
      raise ActionController::BadRequest,
            "invalid range_start (#{blacklight_params[:range_start]}) or range_end (#{blacklight_params[:range_end]})"
    end
  end
end
