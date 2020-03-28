require 'spec_helper'

RSpec.describe BlacklightRangeLimit::ViewHelperOverride, type: :helper do
  describe '#render_constraints_filters' do
    before do
      allow(helper).to receive_messages(
        facet_field_label: 'Date Range',
        remove_range_param: '/remove'
      )
    end

    it 'does not return any content when the range parameter invalid' do
      params = { range: 'garbage' }

      expect(helper.render_constraints_filters(params)).to eq ''
    end

    it 'renders a constraint for the given data in the range param' do
      params = {
        range: { range_field: { 'begin' => 1900, 'end' => 2000 } }
      }
      constraints = helper.render_constraints_filters(params)

      expect(constraints).to have_css(
        '.constraint .filterName', text: 'Date Range'
      )
      expect(constraints).to have_css(
        '.constraint .filterValue', text: '1900 to 2000'
      )
    end
  end

  describe 'render_search_to_s_filters' do
    before do
      allow(helper).to receive_messages(facet_field_label: 'Date Range')
    end

    it 'does not return any content when the range parameter invalid' do
      params = { range: 'garbage' }

      expect(helper.render_search_to_s_filters(params)).to eq ''
    end

    it 'renders a constraint for the given data in the range param' do
      params = {
        range: { range_field: { 'begin' => 1900, 'end' => 2000 } }
      }
      constraints = helper.render_search_to_s_filters(params)

      expect(constraints).to have_css(
        '.constraint .filterName', text: 'Date Range:'
      )
      expect(constraints).to have_css(
        '.constraint .filterValues', text: '1900 to 2000'
      )
    end
  end
end
