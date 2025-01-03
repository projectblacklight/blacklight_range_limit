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
        params[param_key][config.key] = { begin: value.begin, end: value.end }
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
    def values(except: [])
      params = search_state.params
      param_key = filters_key
      range = if !params.try(:dig, param_key).respond_to?(:dig)
        # bad data, not a hash at all, correct it. Yes, it's bad form to mutate
        # params here, but we found no better solution -- this only necessary in BL
        # prior to 8.x, not sure why, but this branch can be omitted in BL 8.
        params.delete(param_key)
        nil
      elsif params.dig(param_key, config.key).is_a? Range
        params.dig(param_key, config.key)
      elsif params.dig(param_key, config.key).is_a? Hash
        b_bound = params.dig(param_key, config.key, :begin).presence
        e_bound = params.dig(param_key, config.key, :end).presence
        Range.new(b_bound&.to_i, e_bound&.to_i) if b_bound || e_bound
      end

      f = except.include?(:filters) ? [] : [range].compact

      f_missing = [] if except.include?(:missing)
      f_missing ||= [Blacklight::SearchState::FilterField::MISSING] if params.dig(filters_key, "-#{key}")&.any? { |v| v == Blacklight::Engine.config.blacklight.facet_missing_param }

      f + (f_missing || [])
    end

    # @param [String,#value] a filter to remove from the url
    # @return [Boolean] whether the provided filter is currently applied/selected
    delegate :include?, to: :values

    # @since Blacklight v7.25.2
    # normal filter fields demangle when they encounter a hash, which they assume to be a number-indexed map
    # this filter should allow (expect) hashes if the keys include 'begin' or 'end'
    def permitted_params
      {
        filters_key => { config.key => [:begin, :end], "-#{config.key}" => [] },
        inclusive_filters_key => { config.key => [:begin, :end] }
      }
    end
  end
end
