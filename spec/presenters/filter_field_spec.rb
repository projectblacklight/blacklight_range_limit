# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlacklightRangeLimit::FilterField do
  let(:search_state) { Blacklight::SearchState.new(params.with_indifferent_access, blacklight_config, controller) }

  let(:params) { {} }
  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.add_facet_field 'some_field', filter_class: described_class
    end
  end
  let(:controller) { double }

  describe '#add' do
    it 'adds a new range parameter' do
      filter = search_state.filter('some_field')
      new_state = filter.add(1999..2099)

      expect(new_state.params.dig(:range, 'some_field')).to include begin: 1999, end: 2099
    end
  end

  context 'with some existing data' do
    let(:params) { { range: { some_field: { begin: '2013', end: '2022' } } } }

    describe '#add' do
      it 'replaces the existing range' do
        filter = search_state.filter('some_field')
        new_state = filter.add(1999..2099)

        expect(new_state.params.dig(:range, 'some_field')).to include begin: 1999, end: 2099
      end
    end

    describe '#remove' do
      it 'removes the existing range' do
        filter = search_state.filter('some_field')
        new_state = filter.remove(2013..2022)

        expect(new_state.params.dig(:range, 'some_field')).to be_blank
      end
    end

    describe '#values' do
      it 'converts the parameters to a Range' do
        filter = search_state.filter('some_field')

        expect(filter.values).to eq [2013..2022]
      end
    end

    describe '#include?' do
      it 'compares the provided value to the parameter values' do
        filter = search_state.filter('some_field')

        expect(filter.include?(2013..2022)).to eq true
        expect(filter.include?(1234..2345)).to eq false
      end
    end
  end
end
