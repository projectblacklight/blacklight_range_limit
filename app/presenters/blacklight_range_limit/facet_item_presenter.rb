# frozen_string_literal: true

module BlacklightRangeLimit
  # Override the default item presenter to provide custom labels for
  # range data.
  class FacetItemPresenter < Blacklight::FacetItemPresenter
    def label
      label_for_range || super
    end

    # Very hacky way to keep params used for ajax query for segments out
    # of our facet links. There oughta be a better way?
    #
    # https://github.com/projectblacklight/blacklight_range_limit/issues/296
    def href(path_options = {})
      override_to_nil = BlacklightRangeLimit::ControllerOverride::RANGE_LIMIT_FIELDS.collect { |f| [f, nil] }.to_h
      super(path_options.merge(override_to_nil))
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
      if value.begin == value.end
        'blacklight.range_limit.single_html'
      else
        'blacklight.range_limit.range_html'
      end
    end

    ##
    # A method that is meant to be overridden downstream to format how a range
    # label might be displayed to a user. By default it just returns the value.
    def format_range_display_value(value)
      value
    end
  end
end
