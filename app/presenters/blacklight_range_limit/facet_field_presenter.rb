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

      Blacklight::Solr::Response::Facets::FacetItem.new(value: selected_range, hits: selected_range_hits)
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
      json_facet_stats.dig('missing', 'count') || stats_for_field.fetch('missing', 0)
    end

    # Read range stats from the JSON Facet API response.
    # The range_limit_builder stores them under "<solr_field>_range_stats".
    def json_facet_stats
      response.dig('facets', "#{facet_field.field}_range_stats") || {}
    end

    # Legacy stats-component path – kept as a fallback so that the presenter
    # still works when the upstream application has not yet switched its Solr
    # request handler to the JSON Facet API approach.
    def stats_for_field
      response.dig('stats', 'stats_fields', facet_field.field) || {}
    end

    # type is 'min' or 'max'
    # Returns smallest and largest value in current result set, if available
    # from the JSON Facet API response (preferred) or the stats component
    # response (legacy fallback).
    def range_results_endpoint(type)
      type_s = type.to_s

      # Try JSON Facet API first
      json_stats = json_facet_stats
      if json_stats.key?(type_s)
        raw = json_stats[type_s]
        return nil if raw.nil?

        # Check if all docs are missing a value – no meaningful min/max
        missing_count = json_stats.dig('missing', 'count') || 0
        return nil if selected_range_hits == missing_count && missing_count > 0

        year = BlacklightRangeLimit.year_from_solr_date(raw)
        return year.to_s if year
      end

      # Fall back to legacy stats component
      stats = stats_for_field
      return nil unless stats.key? type_s
      return nil if selected_range_hits == stats['missing']

      stats[type_s].to_s.gsub(/\.0+/, '')
    end

    def selected_range_hits
      return response.total unless response.grouped?

      # The total doc count when results are *grouped* is located at a
      # different key path than in a normal ungrouped response.
      # If a config.index.group field is set via blacklight_config, use that.
      # Otherwise, use the first (and likely only) group key in the response.
      group_key = blacklight_config.view_config(action_name: :index).group || response.grouped.first.key
      response.dig('grouped', group_key, 'matches')
    end
  end
end
