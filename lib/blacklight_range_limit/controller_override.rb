# Meant to be applied on top of a controller that implements
# Blacklight::SolrHelper. Will inject range limiting behaviors
# to solr parameters creation.
require 'blacklight_range_limit/segment_calculation'
module BlacklightRangeLimit
  module ControllerOverride
    extend Deprecation
    extend ActiveSupport::Concern

    RANGE_LIMIT_FIELDS = [:range_end, :range_field, :range_start].freeze

    included do
      before_action do
        # Blacklight 7.25+: Allow range limit params if necessary
        if blacklight_config.search_state_fields
          missing_keys = RANGE_LIMIT_FIELDS - blacklight_config.search_state_fields
          blacklight_config.search_state_fields.concat(missing_keys)
        end
      end
    end

    # Action method of our own!
    # Delivers a _partial_ that's a display of a single fields range facets.
    # Used when we need a second Solr query to get range facets, after the
    # first found min/max from result set.
    def range_limit
      @facet = blacklight_config.facet_fields[params[:range_field]]
      raise ActionController::RoutingError, 'Not Found' unless @facet&.range

      # We need to swap out the add_range_limit_params search param filter,
      # and instead add in our fetch_specific_range_limit filter,
      # to fetch only the range limit segments for only specific
      # field (with start/end params) mentioned in query params
      # range_field, range_start, and range_end

      @response, _ = search_service.search_results do |search_builder|
        search_builder.except(:add_range_limit_params).append(:fetch_specific_range_limit)
      end

      display_facet = @response.aggregations[@facet.field] || Blacklight::Solr::Response::Facets::FacetField.new(@facet.key, [], response: @response)

      @presenter = (@facet.presenter || BlacklightRangeLimit::FacetFieldPresenter).new(@facet, display_facet, view_context)

      render BlacklightRangeLimit::RangeSegmentsComponent.new(facet_field: @presenter), layout: !request.xhr?
    end

    def range_limit_panel
      Deprecation.warn(BlacklightRangeLimit::ControllerOverride, 'range_limit_panel is deprecated; use the normal facet modal route instead')
      facet
    end

    class_methods do
      def default_range_config
        BlacklightRangeLimit.default_range_config
      end
    end
  end
end
