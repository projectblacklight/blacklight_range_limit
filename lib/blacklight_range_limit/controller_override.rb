# Meant to be applied on top of a controller that implements
# Blacklight::SolrHelper. Will inject range limiting behaviors
# to solr parameters creation.
require 'blacklight_range_limit/segment_calculation'
module BlacklightRangeLimit
  module ControllerOverride
    extend ActiveSupport::Concern

    RANGE_LIMIT_FIELDS = [:range_end, :range_field, :range_start].freeze

    included do
      # have to do this in before_action so it's done before any application level
      # before_actions, that might do something that needs it
      before_action :_range_limit_add_search_state_fields, only: :range_limit
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

    def _range_limit_add_search_state_fields
      # The builder in this action will need our special range_limit fields, so we
      # must allow them.
      blacklight_config.search_state_fields ||= []
      missing_keys = RANGE_LIMIT_FIELDS - blacklight_config.search_state_fields
      blacklight_config.search_state_fields.concat(missing_keys)
    end

    class_methods do
      def default_range_config
        BlacklightRangeLimit.default_range_config
      end
    end
  end
end
