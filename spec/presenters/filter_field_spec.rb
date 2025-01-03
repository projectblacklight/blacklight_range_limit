# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlacklightRangeLimit::FilterField do
  let(:search_state) { Blacklight::SearchState.new(params, blacklight_config, controller) }

  let(:param_values) { {} }
  let(:params) { ActionController::Parameters.new(param_values) }
  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.add_facet_field 'some_field', filter_class: described_class
      config.filter_search_state_fields = true
    end
  end
  let(:controller) { double }
  let(:filter) { search_state.filter('some_field') }

  describe '#add' do
    it 'adds a new range parameter' do
      new_state = filter.add(1999..2099)
      expect(new_state.params.dig(:range, 'some_field')).to include begin: 1999, end: 2099
    end

    it "adds end-less range" do
      new_state = filter.add(1999..nil)
      expect(new_state.params.dig(:range, 'some_field')).to include begin: 1999, end: nil
    end

    it "adds begin-less range" do
      new_state = filter.add(nil..2099)
      expect(new_state.params.dig(:range, 'some_field')).to include begin: nil, end: 2099
    end
  end

  context 'with some existing data' do
    let(:param_values) { { range: { some_field: { begin: '2013', end: '2022' } } } }

    describe '#add' do
      it 'replaces the existing range' do
        new_state = filter.add(1999..2099)

        expect(new_state.params.dig(:range, 'some_field')).to include begin: 1999, end: 2099

        new_state = filter.add(1999..nil)
        expect(new_state.params.dig(:range, 'some_field')).to include begin: 1999, end: nil

        new_state = filter.add(nil..2099)
        expect(new_state.params.dig(:range, 'some_field')).to include begin: nil, end: 2099
      end
    end

    describe '#remove' do
      it 'removes the existing range' do
        new_state = filter.remove(2013..2022)

        expect(new_state.params.dig(:range, 'some_field')).to be_blank
      end
    end

    describe '#values' do
      it 'converts the parameters to a Range' do
        expect(filter.values).to eq [2013..2022]
      end
    end

    describe '#include?' do
      it 'compares the provided value to the parameter values' do
        expect(filter.include?(2013..2022)).to eq true
        expect(filter.include?(1234..2345)).to eq false
      end
    end

    describe '#permitted_params' do
      let(:rails_params) { ActionController::Parameters.new(param_values) }
      let(:blacklight_params) { Blacklight::Parameters.new(rails_params, search_state) }
      let(:permitted_params) { blacklight_params.permit_search_params.to_h }
      it 'sanitizes single begin/end values as scalars' do
        expect(permitted_params.dig(:range, 'some_field')).to include 'begin' => '2013', 'end' => '2022'
      end
    end
  end

  context 'with an end-less range' do
    let(:param_values) { { range: { some_field: { begin: '2013', end: '' } } } }

    describe '#values' do
      it 'converts the parameters to a Range' do
        expect(filter.values).to eq [2013..nil]
      end
    end
  end

  context 'with an begin-less range' do
    let(:param_values) { { range: { some_field: { begin: '', end: '2022' } } } }

    describe '#values' do
      it 'converts the parameters to a Range' do
        expect(filter.values).to eq [nil..2022]
      end
    end
  end

  context 'with empty data' do
    let(:param_values) { { range: { some_field: { begin: '', end: '' } } } }

    describe '#values' do
      it 'drops the empty range' do
        expect(filter.values).to be_empty
      end
    end
  end

  context 'with missing data' do
    let(:param_values) { { range: { '-some_field': ['[* TO *]']} } }

    describe '#values' do
      it 'uses the missing special value' do
        expect(filter.values).to eq [Blacklight::SearchState::FilterField::MISSING]
      end
    end
  end
end
