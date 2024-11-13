require 'blacklight_range_limit/segment_calculation'

module BlacklightRangeLimit
  module RangeLimitBuilder
    extend ActiveSupport::Concern
    include BlacklightRangeLimit::SegmentCalculation

    included do
      # Use setters so not to propagate changes
      self.default_processor_chain += [:add_range_limit_params]
    end

    # Method added to to fetch proper things for date ranges.
    def add_range_limit_params(solr_params)
      ranged_facet_configs = blacklight_config.facet_fields.select { |_key, config| config.range }
      return solr_params unless ranged_facet_configs.any?

      solr_params["stats"] = "true"
      solr_params["stats.field"] ||= []

      ranged_facet_configs.each do |field_key, config|
        solr_params["stats.field"] << config.field

        range_config = config.range_config
        next unless range_config[:chart_js] || range_config[:textual_facets]

        selected_value = search_state.filter(config.key).values.first

        range = if selected_value.is_a? Range
          selected_value
        elsif range_config[:assumed_boundaries]
          Range.new(*range_config[:assumed_boundaries])
        else
          nil
        end

        # If we have both ends of a range
        add_range_segments_to_solr!(solr_params, field_key, range.begin, range.end) if range && range.count != Float::INFINITY
      end

      solr_params
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
      start = blacklight_params[:range_start].to_i
      finish = blacklight_params[:range_end].to_i

      add_range_segments_to_solr!(solr_params, field_key, start, finish )

      # Remove all field faceting for efficiency, we won't be using it.
      solr_params.delete("facet.field")
      solr_params.delete("facet.field".to_sym)

      # We don't need any actual rows either
      solr_params[:rows] = 0

      return solr_params
    end

    # hacky polyfill for new Blacklight behavior we need, if we don't have it yet
    #
    # https://github.com/projectblacklight/blacklight/pull/3213
    # https://github.com/projectblacklight/blacklight/pull/3443
    bl_version = Gem.loaded_specs["blacklight"]&.version
    if bl_version && (bl_version <= Gem::Version.new("8.6.1"))
      def facet_value_to_fq_string(facet_field, value, use_local_params: true)
        facet_config = blacklight_config.facet_fields[facet_field]

        # if it's an one-end range, and condition from original that would use query instead isn't met
        if value.is_a?(Range) && (value.count == Float::INFINITY) && !facet_config&.query
          solr_field = facet_config.field if facet_config && !facet_config.query
          solr_field ||= facet_field

          local_params = []
          local_params << "tag=#{facet_config.tag}" if use_local_params && facet_config && facet_config.tag

          "#{solr_field}:[#{value.begin || "*"} TO #{value.end || "*"}]"
        else
          super
        end
      end
    end

  end
end
