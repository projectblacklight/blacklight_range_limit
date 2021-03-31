require 'spec_helper'

RSpec.describe BlacklightRangeLimit::ViewHelperOverride, type: :helper do
  let (:blacklight_config) {
    config = CatalogController.blacklight_config
    config.facet_fields['range_field'] = Blacklight::Configuration::Field.new(range: true)
    config
  }

  describe '#render_constraints_filters' do
    before do
      allow(helper).to receive_messages(
        facet_field_label: 'Date Range',
        remove_range_param: {},
        search_action_path: '/catalog',
        blacklight_config: blacklight_config,
        search_state: {},
      )
      allow(controller).to receive_messages(
        search_state_class: Blacklight::SearchState,
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
        '.constraint .filter-name', text: 'Date Range'
      )
      expect(constraints).to have_css(
        '.constraint .filter-value', text: '1900 to 2000'
      )
    end
  end

  describe 'render_search_to_s_filters' do
    before do
      allow(helper).to receive_messages(
        facet_field_label: 'Date Range',
        blacklight_config: blacklight_config,
        search_state: {},
      )
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
        '.constraint .filter-name', text: 'Date Range:'
      )
      expect(constraints).to have_css(
        '.constraint .filter-values', text: '1900 to 2000'
      )
    end
  end

  describe '#range_params' do
    let (:blacklight_config) {
      config = CatalogController.blacklight_config
      config.facet_fields['field_name'] = Blacklight::Configuration::Field.new(range: true)
      config.facet_fields['field_name2'] = Blacklight::Configuration::Field.new(range: true)
      config.facet_fields['blah'] = Blacklight::Configuration::Field.new(range: true)
      config.facet_fields['wrong'] = Blacklight::Configuration::Field.new(range: true)
      config
    }

    before do
      allow(helper).to receive_messages(
        facet_field_label: 'Date Range',
        blacklight_config: blacklight_config,
        search_state: {},
      )
    end

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

    it 'does not return a range parameter if it is not a configured facet field' do
      expect(
        helper.send(
          :range_params,
          ActionController::Parameters.new(
            range: {
              field_name: { 'begin' => '1800', 'end' => '1900' },
              field_name3: { 'begin' => '1800', 'end' => '1900' }
            }
          )
        ).permit!.to_h
      ).to eq(
        {
          'field_name' => { 'begin' => '1800', 'end' => '1900' },
        }
      )
    end
  end
end
