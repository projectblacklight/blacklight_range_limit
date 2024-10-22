# frozen_string_literal: true

module BlacklightRangeLimit
  class RangeFacetComponent < Blacklight::Component
    delegate :search_action_path, :search_facet_path, to: :helpers

    def initialize(facet_field:, layout: nil, classes: BlacklightRangeLimit.classes)
      @facet_field = facet_field
      @layout = layout == false ? Blacklight::FacetFieldNoLayoutComponent : Blacklight::FacetFieldComponent
      @classes = classes
    end

    def range_config
      @facet_field.range_config
    end

    def range_limit_url(options = {})
      helpers.main_app.url_for(@facet_field.search_state.to_h.merge(range_field: @facet_field.key, action: 'range_limit').merge(options))
    end
  end
end
