# frozen_string_literal: true

module BlacklightRangeLimit
  class RangeSegmentsComponent < Blacklight::Component
    def initialize(facet_field:, facet_items: nil, item_component: nil, classes: [])
      super

      @facet_field = facet_field
      @facet_items = facet_items || facet_field.try(:range_queries) || []
      # newer versions of BL9 want Blacklight::Facets::ItemComponent -- the older one is supposed
      # to be deprecated, but in fact may not work so we use newer if avail.
      @item_component = facet_field.facet_field.item_component ||
        (defined?(Blacklight::Facets::ItemComponent) ? Blacklight::Facets::ItemComponent : Blacklight::FacetItemComponent)
      @classes = classes
    end

    def facet_item_presenters
      @facet_items.map { |item| facet_item_presenter(item) }
    end

    def facet_item_presenter(facet_item)
      facet_config.item_presenter.new(facet_item, facet_config, helpers, @facet_field.key)
    end

    def facet_config
      @facet_field.facet_field
    end
  end
end
