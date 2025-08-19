# frozen_string_literal: true

module BlacklightRangeLimit
  class RangeInputComponent < Blacklight::Component
      def initialize(input_name:, input_value:, label_text:, min_value:, max_value:, css_class:)
        @input_name = input_name
        @input_value = input_value
        @label_text = label_text
        @min_value = min_value
        @max_value = max_value
        @css_class = css_class
      end
  end
end
