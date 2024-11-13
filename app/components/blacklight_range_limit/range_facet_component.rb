# frozen_string_literal: true

module BlacklightRangeLimit
  class RangeFacetComponent < Blacklight::Component
    delegate :search_action_path, :search_facet_path, to: :helpers

    def initialize(facet_field:, layout: nil, classes: BlacklightRangeLimit.classes)
      @facet_field = facet_field
      @layout = layout == false ? Blacklight::FacetFieldNoLayoutComponent : Blacklight::FacetFieldComponent
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
  end
end
