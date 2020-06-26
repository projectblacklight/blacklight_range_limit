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
      params = ActionController::Parameters.new(range: 'garbage')

      expect(helper.render_constraints_filters(params)).to eq ''
    end

    it 'renders a constraint for the given data in the range param' do
      params = ActionController::Parameters.new(
        range: { range_field: { 'begin' => 1900, 'end' => 2000 } }
      )
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
      params = ActionController::Parameters.new(range: 'garbage')

      expect(helper.render_search_to_s_filters(params)).to eq ''
    end

    it 'renders a constraint for the given data in the range param' do
      params = ActionController::Parameters.new(
        range: { range_field: { 'begin' => 1900, 'end' => 2000 } }
      )
      constraints = helper.render_search_to_s_filters(params)

      expect(constraints).to have_css(
        '.constraint .filterName', text: 'Date Range:'
      )
      expect(constraints).to have_css(
        '.constraint .filterValues', text: '1900 to 2000'
      )
    end
  end

  describe '#range_params' do
    it 'handles no range input' do
      expect(
        helper.send(:range_params, ActionController::Parameters.new(q: 'blah'))
      ).to eq({})
    end

    it 'handles non-compliant range input' do
      expect(
        helper.send(:range_params, ActionController::Parameters.new(range: 'blah'))
      ).to eq({})

      expect(
        helper.send(:range_params, ActionController::Parameters.new(range: ['blah']))
      ).to eq({})

      expect(
        helper.send(:range_params, ActionController::Parameters.new(range: { 'wrong' => 'data' }))
      ).to eq({})

      expect(
        helper.send(
          :range_params,
          ActionController::Parameters.new(range: { field_name: { 'wrong' => 'data' } })
        )
      ).to eq({})

      expect(
        helper.send(
          :range_params,
          ActionController::Parameters.new(range: { field_name: { 'begin' => '', 'end' => '' } })
        )
      ).to eq({})
    end

    it 'returns the range parameters that are present' do
      expect(
        helper.send(
          :range_params,
          ActionController::Parameters.new(range: { field_name: { 'missing' => true } })
        ).permit!.to_h
      ).to eq({ 'field_name' => { 'missing' => true } })

      expect(
        helper.send(
          :range_params,
          ActionController::Parameters.new(range: { field_name: { 'begin' => '1800', 'end' => '1900' } })
        ).permit!.to_h
      ).to eq({ 'field_name' => { 'begin' => '1800', 'end' => '1900' } })

      expect(
        helper.send(
          :range_params,
          ActionController::Parameters.new(
            range: {
              field_name: { 'begin' => '1800', 'end' => '1900' },
              field_name2: { 'begin' => '1800', 'end' => '1900' }
            }
          )
        ).permit!.to_h
      ).to eq(
        {
          'field_name' => { 'begin' => '1800', 'end' => '1900' },
          'field_name2' => { 'begin' => '1800', 'end' => '1900' }
        }
      )
    end
  end
end
