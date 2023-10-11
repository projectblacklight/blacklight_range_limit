# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlacklightRangeLimit::RangeFormComponent, type: :component do
  subject(:component) do
    described_class.new(facet_field: facet_field)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render_inline(component))
  end

  let(:facet_field_params) { {} }
  let(:extra_facet_field_params) { Blacklight::VERSION > '8' ? {} : { html_id: 'id' } }
  let(:selected_range) { nil }
  let(:search_params) { { another_field: 'another_value' } }

  let(:facet_field) do
    instance_double(
      BlacklightRangeLimit::FacetFieldPresenter,
      key: 'key',
      active?: false,
      collapsed?: false,
      in_modal?: false,
      label: 'My facet field',
      selected_range: selected_range,
      selected_range_facet_item: nil,
      missing_facet_item: nil,
      missing_selected?: false,
      min: nil,
      max: nil,
      search_state: Blacklight::SearchState.new(search_params, nil),
      range_config: {},
      modal_path: nil,
      facet_field: facet_config,
      **facet_field_params,
      **extra_facet_field_params
    )
  end

  let(:facet_config) do
    Blacklight::Configuration::FacetField.new(key: 'key', item_presenter: BlacklightRangeLimit::FacetItemPresenter)
  end

  it 'renders a form with no selected range' do
    expect(rendered).to have_selector('form[action="http://test.host/catalog"][method="get"]')
      .and have_field('range[key][begin]', type: 'number')
      .and have_field('range[key][end]', type: 'number')
      .and have_field('another_field', type: 'hidden', with: 'another_value', visible: false)
    expect(rendered.find_field('range[key][begin]', type: 'number').value).to be_blank
    expect(rendered.find_field('range[key][end]', type: 'number').value).to be_blank
    expect(rendered).not_to have_field('range[key][begin]', type: 'hidden')
  end

  it 'renders submit controls without a name to suppress from formData' do
    anon_submit = rendered.find('input', visible: true) { |ele| ele[:type] == 'submit' && !ele[:'aria-hidden'] && !ele[:name] }
    expect(anon_submit).to be_present
    expect { rendered.find('input') { |ele| ele[:type] == 'submit' && ele[:name] } }.to raise_error(Capybara::ElementNotFound)
  end

  context 'with range data' do
    let(:selected_range) { (100..300) }
    let(:search_params) do
      { 
        another_field: 'another_value',
        range: {
          another_range: { begin: 128, end: 1024 },
          key: { begin: selected_range.first, end: selected_range.last }
        }
      }      
    end

    it 'renders a form for the selected range' do
      expect(rendered).to have_selector('form[action="http://test.host/catalog"][method="get"]')
        .and have_field('range[key][begin]', type: 'number', with: selected_range.first)
        .and have_field('range[key][end]', type: 'number', with: selected_range.last)
        .and have_field('another_field', type: 'hidden', with: 'another_value', visible: false)
        .and have_field('range[another_range][begin]', type: 'hidden', with: 128, visible: false)
        .and have_field('range[another_range][end]', type: 'hidden', with: 1024, visible: false)
      expect(rendered).not_to have_field('range[key][begin]', type: 'hidden')
    end
  end
end
