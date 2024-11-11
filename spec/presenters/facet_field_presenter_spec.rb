# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlacklightRangeLimit::FacetFieldPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new(facet_field, display_facet, view_context, search_state)
  end
  let(:view_context) { controller.view_context }
  let(:search_state) { Blacklight::SearchState.new(params, blacklight_config, view_context) }

  let(:facet_field) do
    Blacklight::Configuration::FacetField.new(
      key: 'field_key',
      field: 'some_field',
      filter_class: BlacklightRangeLimit::FilterField
    )
  end
  let(:blacklight_config) do
    Blacklight::Configuration.new.tap { |x| x.facet_fields['field_key'] = facet_field }
  end
  let(:params) { {} }

  let(:display_facet) do
    instance_double(Blacklight::Solr::Response::Facets::FacetField, items: [], response: response)
  end
  let(:response) do
    Blacklight::Solr::Response.new(
      {
        response: { numFound: 5 },
        stats: {
          stats_fields: {
            some_field: some_field_stats
          }
        }
      },
      nil
    )
  end

  let(:some_field_stats) { {} }

  describe '#range_queries' do
    let(:response) do
      {
        'facet_counts' => {
          'facet_queries' => {
            'some_field:[150 TO 199]' => 15,
            'some_field:[100 TO 149]' => 5,
            'some_field:[200 TO 249]' => 4,
            'irrelevant_field:[A TO C]' => 18
          }
        }
      }
    end

    it 'extracts range data from the facet queries response' do
      expect(presenter.range_queries.count).to eq 3
      expect(presenter.range_queries.map(&:value)).to eq [100..149, 150..199, 200..249]
    end
  end

  describe '#min' do
    let(:some_field_stats) do
      {
        max: 999.00,
        min: 700.0000,
        missing: 0
      }
    end

    it 'extracts the min stat, stringifies it (for some reason), and truncates it' do
      expect(presenter.min).to eq '700'
    end

    context 'when all documents in the response are missing data' do
      let(:some_field_stats) do
        {
          max: -345,
          min: -999,
          missing: 5
        }
      end

      it 'returns nil' do
        expect(presenter.min).to be_nil
      end
    end
  end

  describe '#max' do
    let(:some_field_stats) do
      {
        max: 999.00,
        min: 700.0000,
        missing: 0
      }
    end

    it 'extracts the ,ax stat, stringifies it (for some reason), and truncates it' do
      expect(presenter.max).to eq '999'
    end

    context 'when all documents in the response are missing data' do
      let(:some_field_stats) do
        {
          max: -345,
          min: -999,
          missing: 5
        }
      end

      it 'returns nil' do
        expect(presenter.max).to be_nil
      end
    end
  end

  describe '#missing_facet_item' do
    let(:some_field_stats) do
      {
        missing: 5
      }
    end

    it 'extracts the missing stat' do
      expect(presenter.missing_facet_item.hits).to eq 5
    end
  end

  describe '#selected_range' do
    it 'returns nil if no range is selected' do
      expect(presenter.selected_range).to eq nil
    end

    context 'with a user-selected range' do
      let(:params) { { range: { field_key: { begin: 100, end: 250 } } } }

      it 'returns the selected range' do
        expect(presenter.selected_range).to eq 100..250
      end
    end
  end

  describe '#selected_range_facet_item' do
    before do
      allow(presenter).to receive(:selected_range).and_return(1990..1999)
    end

    context 'when the response is not a grouped response' do
      let(:response) do
        Blacklight::Solr::Response.new(
          {
            response: { numFound: 501 }
          },
          nil
        )
      end

      it 'returns the facet item with the correct value and hits' do
        expected_facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(value: 1990..1999, hits: 501)
        expect(presenter.selected_range_facet_item).to eq expected_facet_item
      end
    end

    context 'when the response is a grouped response with one group' do
      let(:response) do
        Blacklight::Solr::Response.new(
          {
            grouped: {
              _root_: {
                matches: 123
              }
            }
          },
          nil
        )
      end

      it 'returns the facet item with the hits from the group' do
        expected_facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(value: 1990..1999, hits: 123)
        expect(presenter.selected_range_facet_item).to eq expected_facet_item
      end
    end

    context 'when the response is a grouped response with multiple groups' do
      let(:response) do
        Blacklight::Solr::Response.new(
          {
            grouped: {
              field_one_ssi: {
                matches: 123
              },
              field_two_ssi: {
                matches: 456
              }
            }
          },
          nil
        )
      end

      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.facet_fields['field_key'] = facet_field
          config.index.group = 'field_two_ssi'
        end
      end

      it 'returns the facet item with the hits from the configured group' do
        expected_facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(value: 1990..1999, hits: 456)
        expect(presenter.selected_range_facet_item).to eq expected_facet_item
      end
    end
  end
end
