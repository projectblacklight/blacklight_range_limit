# frozen_string_literal: true

module BlacklightRangeLimit
  class RangeFormComponent < Blacklight::Component
    delegate :search_action_path, to: :helpers

    def initialize(facet_field:, classes: BlacklightRangeLimit.classes)
      @facet_field = facet_field
      @classes = classes
    end

    def begin_value_default
      @facet_field.selected_range.is_a?(Range) ? @facet_field.selected_range.begin : @facet_field.min
    end

    def end_value_default
      @facet_field.selected_range.is_a?(Range) ? @facet_field.selected_range.end : @facet_field.max
    end

    def begin_input_name
      "range[#{@facet_field.key}][begin]"
    end

    def end_input_name
      "range[#{@facet_field.key}][end]"
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
