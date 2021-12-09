# frozen_string_literal: true

module BlacklightRangeLimit
  class FacetFieldComponent < ::ViewComponent::Base
    renders_one :more_link, ->(key:, label:) do
      tag.div class: 'more_facets' do
        link_to t('blacklight.range_limit.view_larger', field_name: label),
          search_facet_path(id: key),
          data: { blacklight_modal: 'trigger' }
      end
    end

    delegate :search_action_path, :search_facet_path, to: :helpers

    def initialize(facet_field:, layout: nil, classes: BlacklightRangeLimit.classes)
      @facet_field = facet_field
      @layout = layout == false ? Blacklight::FacetFieldNoLayoutComponent : Blacklight::FacetFieldComponent
      @classes = classes
    end

    def range_config
      @facet_field.range_config
    end

    def begin_label
      range_config[:input_label_range_begin] || t("blacklight.range_limit.range_begin", field_label: @facet_field.label)
    end

    def end_label
      range_config[:input_label_range_end] || t("blacklight.range_limit.range_end", field_label: @facet_field.label)
    end

    def maxlength
      range_config[:maxlength]
    end

    # type is 'begin' or 'end'
    def render_range_input(type, input_label = nil)
      type = type.to_s

      default = if @facet_field.selected_range.is_a?(Range)
                  case type
                  when 'begin' then @facet_field.selected_range.first
                  when 'end' then @facet_field.selected_range.last
                  end
                end

      html = number_field_tag("range[#{@facet_field.key}][#{type}]", default, maxlength: maxlength, class: "form-control text-center range_#{type}")
      html += label_tag("range[#{@facet_field.key}][#{type}]", input_label, class: 'sr-only visually-hidden') if input_label.present?
      html
    end

    def facet_item_presenter(value:, hits:)
      facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(value: value, hits: hits)

      facet_item_presenter(@facet_field.facet_field, facet_item, @facet_field.key)
    end

    def range_limit_url(options = {})
      helpers.main_app.url_for(@facet_field.search_state.to_h.merge(range_field: @facet_field.key, action: 'range_limit').merge(options))
    end
  end
end
