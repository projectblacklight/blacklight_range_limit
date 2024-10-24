# frozen_string_literal: true

module BlacklightRangeLimit
  class RangeFormComponent < Blacklight::Component
    delegate :search_action_path, to: :helpers

    def initialize(facet_field:, classes: BlacklightRangeLimit.classes)
      @facet_field = facet_field
      @classes = classes
    end

    # type is 'begin' or 'end'
    def render_range_input(type)
      type = type.to_s

      if type == "begin"
        default = @facet_field.selected_range.is_a?(Range) ? @facet_field.selected_range.first : @facet_field.min
        extra_class = "mr-1 me-1" # bootstrap 4 and 5
      else
        default = @facet_field.selected_range.is_a?(Range) ? @facet_field.selected_range.last : @facet_field.max
        extra_class = "ml-1 ms-1"
      end

      html = number_field_tag("range[#{@facet_field.key}][#{type}]", default, class: "form-control form-control-sm text-center range_#{type} #{extra_class}")

      html
    end

    private

    ##
    # the form needs to serialize any search parameters, including other potential range filters,
    # as hidden fields. The parameters for this component's range filter are serialized as number
    # inputs, and should not be in the hidden params.
    # @return [Blacklight::HiddenSearchStateComponent]
    def hidden_search_state
      hidden_search_params = @facet_field.search_state.params_for_search.except(:utf8, :page)
      hidden_search_params[:range]&.except!(@facet_field.key)
      Blacklight::HiddenSearchStateComponent.new(params: hidden_search_params)
    end

    def range_config
      @facet_field.range_config
    end
  end
end
