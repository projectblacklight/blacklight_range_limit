# frozen_string_literal: true

module BlacklightRangeLimit
  # Modeling access to filter query parameters
  class FilterField < Blacklight::SearchState::FilterField
    # @param [String,#value] a filter item to add to the url
    # @return [Blacklight::SearchState] new state
    def add(item)
      new_state = search_state.reset_search
      params = new_state.params

      value = as_url_parameter(item)

      if value.is_a? Range
        params[:range] = (params[:range] || {}).dup
        params[:range][config.key] = { begin: value.first, end: value.last }
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
        params[:range] = (params[:range] || {}).dup
        params[:range]&.delete(config.key)
        new_state.reset(params)
      else
        super
      end
    end

    # @return [Array] an array of applied filters
    def values
      params = search_state.params
      return super unless params.dig(:range, config.key)

      range = if params.dig(:range, config.key).is_a? Range
        params.dig(:range, config.key)
      else
        params.dig(:range, config.key, :begin).to_i..params.dig(:range, config.key, :end).to_i
      end

      return super + [range]
    end

    # @param [String,#value] a filter to remove from the url
    # @return [Boolean] whether the provided filter is currently applied/selected
    delegate :include?, to: :values
  end
end
