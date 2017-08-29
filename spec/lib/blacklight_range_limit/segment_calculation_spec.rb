require 'spec_helper'

RSpec.describe BlacklightRangeLimit::SegmentCalculation do
  let(:dummy_class) do
    Class.new do
      include BlacklightRangeLimit::SegmentCalculation
    end
  end

  describe '#boundaries_for_range_facets' do
    subject { dummy_class.new.send(:boundaries_for_range_facets, first, last, num_div) }

    context "the happy path" do
      let(:first) { 1000 }
      let(:last) { 2008 }
      let(:num_div) { 10 }

      it { is_expected.to eq [1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000, 2009] }
    end

    context 'when the last is before the first' do
      let(:first) { 1000 }
      let(:last) { 800 }
      let(:num_div) { 3 }

      it 'raises and error' do
        expect { subject }.to raise_error ArgumentError,
                                          'The first date must be before the last date'
      end
    end
  end

  describe "#add_range_segments_to_solr!" do
    subject { dummy_class.new.send(:add_range_segments_to_solr!, solr_params, solr_field, min, max) }

    let(:solr_params) { {} }
    let(:solr_field) { 'date_dt' }

    context 'when the last is before the first' do
      let(:min) { 1000 }
      let(:max) { 800 }

      it 'raises an error' do
        expect { subject }.to raise_error BlacklightRangeLimit::InvalidRange,
                                          'The min date must be before the max date'
      end
    end
  end
end
