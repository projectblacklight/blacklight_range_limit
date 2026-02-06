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

      # Build JSON facet API queries for min/max/missing per field,
      # replacing the stats component which does not work with DateRangeField.
      json_facet = solr_params.delete('json.facet') || {}
      json_facet = JSON.parse(json_facet) if json_facet.is_a?(String)

      ranged_facet_configs.each do |field_key, config|
        solr_field = config.field

        # Use a nested JSON facet to get min, max, and missing for this field.
        # We wrap them under a single key so they are easy to find in the response.
        json_facet["#{solr_field}_range_stats"] = {
          type: 'query',
          q: '*:*',
          facet: {
            min: "min(#{solr_field})",
            max: "max(#{solr_field})",
            missing: { type: 'query', q: "-#{solr_field}:[* TO *]" }
          }
        }

        range_config = config.range_config
        next unless range_config[:chart_js] || range_config[:textual_facets]

        selected_value = search_state.filter(config.key).values.first

        range = bl_create_selected_range_value(selected_value, config)

        # If we have both ends of a range
        if range && range.count != Float::INFINITY
          add_range_segments_to_solr!(solr_params, field_key, range.begin, range.end)
        end
      end

      solr_params['json.facet'] = JSON.generate(json_facet)

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

    # hacky polyfill for new Blacklight behavior we need, if we don't have it yet
    #
    # https://github.com/projectblacklight/blacklight/pull/3213
    # https://github.com/projectblacklight/blacklight/pull/3443
    bl_version = Gem.loaded_specs['blacklight']&.version
    if bl_version && (bl_version <= Gem::Version.new('8.6.1'))
      def facet_value_to_fq_string(facet_field, value, use_local_params: true)
        facet_config = blacklight_config.facet_fields[facet_field]

        # if it's an one-end range, and condition from original that would use query instead isn't met
        if value.is_a?(Range) && (value.count == Float::INFINITY) && !facet_config&.query
          # Adapted from
          # https://github.com/projectblacklight/blacklight/blob/1494bd0884efe7a48623e9b37abe558fa6348e2a/lib/blacklight/solr/search_builder_behavior.rb#L362-L366

          solr_field = facet_config.field if facet_config && !facet_config.query
          solr_field ||= facet_field

          local_params = []
          local_params << "tag=#{facet_config.tag}" if use_local_params && facet_config && facet_config.tag

          prefix = "{!#{local_params.join(' ')}}" unless local_params.empty?

          "#{prefix}#{solr_field}:[#{value.begin || '*'} TO #{value.end || '*'}]"
        else
          super
        end
      end
    end

    # @returns Range or nil
    #
    # Range created from a range value or from assumed boundaries if present, and clamped between min and max
    def bl_create_selected_range_value(selected_value, field_config)
      range_config = field_config.range_config

      range = if selected_value.is_a? Range
                selected_value
              elsif range_config[:assumed_boundaries].is_a?(Range)
                range_config[:assumed_boundaries]
              elsif range_config[:assumed_boundaries] # Array of two things please
                Range.new(*range_config[:assumed_boundaries])
              else
                nil
              end

      # clamp between config'd min and max
      min = range_config[:min_value]
      max = range_config[:max_value]

      if range
        range = Range.new(
          (range.begin.clamp(min, max) if range.begin),
          (range.end.clamp(min, max) if range.end)
        )
      end

      range
    end
  end
end
