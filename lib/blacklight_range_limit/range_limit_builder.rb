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
        next if range_config[:segments] == false

        selected_value = search_state.filter(config.key).values.first
        range = (selected_value if selected_value.is_a? Range) || range_config[:assumed_boundaries]

        add_range_segments_to_solr!(solr_params, field_key, range.first, range.last) if range.present?
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

  end
end
