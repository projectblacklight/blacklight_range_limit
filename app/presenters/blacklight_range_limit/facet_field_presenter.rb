# frozen_string_literal: true

module BlacklightRangeLimit
  class FacetFieldPresenter < Blacklight::FacetFieldPresenter
    delegate :response, to: :display_facet
    delegate :blacklight_config, to: :search_state

    def range_queries
      return [] unless response.dig('facet_counts', 'facet_queries')

      range_regex = /#{facet_field.field}: *\[ *(-?\d+) *TO *(-?\d+) *\]/

      array = response.dig('facet_counts', 'facet_queries').map do |query, count|
        if (match = range_regex.match(query))
          Blacklight::Solr::Response::Facets::FacetItem.new(value: match[1].to_i..match[2].to_i, hits: count)
        end
      end

      array.compact.sort_by { |item| item.value.first }
    end

    def paginator
      nil
    end

    def min
      range_results_endpoint(:min)
    end

    def max
      range_results_endpoint(:max)
    end

    def selected_range
      search_state.filter(key).values.first
    end

    def selected_range_facet_item
      return unless selected_range

      Blacklight::Solr::Response::Facets::FacetItem.new(value: selected_range, hits: response.total)
    end

    def missing_facet_item
      return unless missing.positive?

      Blacklight::Solr::Response::Facets::FacetItem.new(
        value: Blacklight::SearchState::FilterField::MISSING,
        hits: missing
      )
    end

    def missing_selected?
      selected_range == Blacklight::SearchState::FilterField::MISSING
    end

    def range_config
      @facet_field.range_config
    end

    private

    def missing
      stats_for_field.fetch('missing', 0)
    end

    def stats_for_field
      response.dig('stats', 'stats_fields', facet_field.field) || {}
    end

    # type is 'min' or 'max'
    # Returns smallest and largest value in current result set, if available
    # from stats component response.
    def range_results_endpoint(type)
      stats = stats_for_field

      return nil unless stats.key? type
      # StatsComponent returns weird min/max when there are in
      # fact no values
      return nil if response.total == stats['missing']

      stats[type].to_s.gsub(/\.0+/, '')
    end
  end
end
