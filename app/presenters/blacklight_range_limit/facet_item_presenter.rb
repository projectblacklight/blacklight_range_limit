# frozen_string_literal: true

module BlacklightRangeLimit
  # Override the default item presenter to provide custom labels for
  # range data.
  class FacetItemPresenter < Blacklight::FacetItemPresenter
    def label
      label_for_range || super
    end

    private

    def label_for_range
      return unless value.is_a? Range

      view_context.t(
        range_limit_label_key,
        begin: format_range_display_value(value.begin),
        begin_value: value.begin,
        end: format_range_display_value(value.end),
        end_value: value.end
      )
    end

    def range_limit_label_key
      if value.count == 1
        'blacklight.range_limit.single_html'
      else
        'blacklight.range_limit.range_html'
      end
    end

    ##
    # A method that is meant to be overridden downstream to format how a range
    # label might be displayed to a user. By default it just returns the value.
    def format_range_display_value(value)
      if view_context.method(:format_range_display_value).owner == RangeLimitHelper
        value
      else
        Deprecation.warn(BlacklightRangeLimit, 'Helper method #format_range_display_value has been overridden; implement a custom FacetItemPresenter instead')
        view_context.format_range_display_value(value, key)
      end
    end
  end
end
