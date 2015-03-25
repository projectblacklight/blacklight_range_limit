module BlacklightRangeLimit
  module SearchBuilderOverride
    include SegmentCalculation

    included do
      default_processor_chain << :add_range_limit_params
    end

    # Method added to solr_search_params_logic to fetch
    # proper things for date ranges.
    def add_range_limit_params(solr_params)
      ranged_facet_configs =
        blacklight_config.facet_fields.select { |key, config| config.range }
      # In ruby 1.8, hash.select returns an array of pairs, in ruby 1.9
      # it returns a hash. Turn it into a hash either way.
      ranged_facet_configs = Hash[ranged_facet_configs] unless ranged_facet_configs.kind_of?(Hash)

      ranged_facet_configs.each_pair do |solr_field, config|
        solr_params["stats"] = "true"
        solr_params["stats.field"] ||= []
        solr_params["stats.field"] << solr_field

        hash =  blacklight_params["range"] && blacklight_params["range"][solr_field] ?
          blacklight_params["range"][solr_field] :
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

          if (config.segments != false && start != "*" && finish != "*")
            # Add in our calculated segments, can only do with both boundaries.
            add_range_segments_to_solr!(solr_params, solr_field, start.to_i, finish.to_i)
          end

        elsif (config.segments != false &&
               boundaries = config.assumed_boundaries)
          # assumed_boundaries in config
          add_range_segments_to_solr!(solr_params, solr_field, boundaries[0], boundaries[1])
        end
      end
    end
  end
end
