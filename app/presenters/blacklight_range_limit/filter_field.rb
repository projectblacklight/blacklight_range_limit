# frozen_string_literal: true

module BlacklightRangeLimit
  # Modeling access to filter query parameters
  class FilterField < Blacklight::SearchState::FilterField
    # this accessor is unnecessary after Blacklight 7.25.0
    attr_accessor :filters_key

    def initialize(config, search_state)
      super
      @filters_key = :range
    end

    # @param [String,#value] a filter item to add to the url
    # @return [Blacklight::SearchState] new state
    def add(item)
      new_state = search_state.reset_search
      params = new_state.params

      value = as_url_parameter(item)

      if value.is_a? Range
        param_key = filters_key
        params[param_key] = (params[param_key] || {}).dup
        params[param_key][config.key] = { begin: value.first, end: value.last }
        new_state.reset(params)
      else
        super
      end
    end

    # @param [String,#value] a filter to remove from the url
    # @return [Blacklight::SearchState] new state
    def remove(item)
      new_state = search_state.reset_search
      params = new_state.params
      value = as_url_parameter(item)

      if value.is_a? Range
        param_key = filters_key
        params[param_key] = (params[param_key] || {}).dup
        params[param_key]&.delete(config.key)
        new_state.reset(params)
      else
        super
      end
    end

    # @return [Array] an array of applied filters
    def values
      params = search_state.params
      param_key = filters_key
      return super unless params.dig(param_key, config.key)

      range = if params.dig(param_key, config.key).is_a? Range
        params.dig(param_key, config.key)
      else
        params.dig(param_key, config.key, :begin).to_i..params.dig(param_key, config.key, :end).to_i
      end

      return super + [range]
    end

    # @param [String,#value] a filter to remove from the url
    # @return [Boolean] whether the provided filter is currently applied/selected
    delegate :include?, to: :values

    # @since Blacklight v7.25.0
    # normal filter fields demangle when they encounter a hash, which they assume to be a number-indexed map
    # this filter should allow (expect) hashes if the keys include 'begin' or 'end'
    def needs_normalization?(value_params)
      value_params.is_a?(Hash) && (value_params.keys.map(&:to_s) & ['begin', 'end']).blank?
    end

    # @since Blacklight v7.25.0
    # value should be the first value from a mangled hash,
    # otherwise return the value as-is
    def normalize(value_params)
      needs_normalization?(value_params) ? value_params.values.first : value_params
    end
  end
end
