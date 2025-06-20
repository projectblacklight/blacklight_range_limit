# frozen_string_literal: true

module BlacklightRangeLimit
  class RangeFacetComponent < Blacklight::Component
    delegate :search_action_path, :search_facet_path, to: :helpers

    def initialize(facet_field:, layout: nil, classes: BlacklightRangeLimit.classes)
      @facet_field = facet_field
      @layout = if layout == false
                  Blacklight::FacetFieldNoLayoutComponent
                elsif layout
                  layout
                elsif defined?(Blacklight::Facets::FacetFieldComponent)
                  Blacklight::Facets::FacetFieldComponent # Blacklight 9
                else
                  Blacklight::FacetFieldComponent # Blacklight < 9
                end

      @classes = classes
    end

    # Don't render if we have no values at all -- most commonly on a zero results page.
    # Normally we'll have at least a min and a max (of values in result set, solr returns),
    # OR a count of objects missing a value -- if we don't have ANY of that, there is literally
    # nothing we can display, and we're probably in a zero results situation.
    def render?
      (@facet_field.min.present? && @facet_field.max.present?) ||
        @facet_field.missing_facet_item.present?
    end

    def range_config
      @facet_field.range_config
    end

    def range_limit_url(options = {})
      helpers.main_app.url_for(@facet_field.search_state.to_h.merge(range_field: @facet_field.key,
                                                                    action: 'range_limit').merge(options))
    end

    def uses_distribution?
      range_config[:chart_js] || range_config[:textual_facets]
    end

    # URL that will return the distribution list of range seguments
    def load_distribution_link
      # For open-ended ranges, the selected range should take priority for the boundary
      # over actual response min/max. Matters for multi-valued fields.
      min = @facet_field.selected_range_facet_item&.value&.begin || @facet_field.min
      max = @facet_field.selected_range_facet_item&.value&.end || @facet_field.max

      return nil unless min && max

      range_limit_url(range_start: min, range_end: max)
    end
  end
end
