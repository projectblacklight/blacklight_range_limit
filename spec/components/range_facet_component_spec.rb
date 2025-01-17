# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlacklightRangeLimit::RangeFacetComponent, type: :component do
  subject(:component) do
    described_class.new(facet_field: facet_field)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render_inline(component))
  end

  let(:facet_field) do
    instance_double(
      BlacklightRangeLimit::FacetFieldPresenter,
      key: 'key',
      active?: false,
      collapsed?: false,
      in_modal?: false,
      label: 'My facet field',
      selected_range: nil,
      selected_range_facet_item: nil,
      missing_facet_item: nil,
      missing_selected?: false,
      min: nil,
      max: nil,
      search_state: Blacklight::SearchState.new({}, nil),
      range_config: BlacklightRangeLimit.default_range_config[:range_config],
      modal_path: nil,
      facet_field: facet_config,
      **facet_field_params,
      **extra_facet_field_params
    )
  end

  let(:facet_config) do
    Blacklight::Configuration::FacetField.new(key: 'key', item_presenter: BlacklightRangeLimit::FacetItemPresenter)
  end

  let(:facet_field_params) { {} }
  let(:extra_facet_field_params) { Blacklight::VERSION > '8' ? {} : { html_id: 'id' } }

  before do
    allow(component).to receive(:search_facet_path).and_return('/range/key')
  end

  context 'with range data' do
    let(:facet_field_params) do
      {
        range_queries: [
          OpenStruct.new(value: 100..199, hits: 5),
          OpenStruct.new(value: 200..300, hits: 3)
        ],
        min: 100,
        max: 300
      }
    end

    it 'renders into the default facet layout' do
      expect(rendered).to have_selector('h3', text: 'My facet field')
        .and have_selector('div.collapse')
    end

    it 'renders the range data into the profile' do
      expect(rendered).to have_selector('.distribution li', count: 2)
        .and have_selector('.distribution li', text: '100 to 199')
        .and have_selector('.distribution li', text: '200 to 300')
    end

    it 'renders a form for the range' do
      expect(rendered).to have_selector('form[action="http://test.host/catalog"][method="get"]')
        .and have_field('range[key][begin]')
        .and have_field('range[key][end]')
    end

    it 'does not render the missing link if there are no matching documents' do
      expect(rendered).not_to have_link '[Missing]'
    end
  end

  context 'with missing documents' do
    let(:facet_field_params) { { missing_facet_item: facet_item } }
    let(:facet_item) do
      Blacklight::Solr::Response::Facets::FacetItem.new(
        value: Blacklight::SearchState::FilterField::MISSING,
        hits: 50
      )
    end

    it 'renders a facet value for the documents that are missing the field data' do
      expected_facet_query_param = Regexp.new(Regexp.escape({ f: { '-key': ['[* TO *]'] } }.to_param))
      expect(rendered).to have_link '[Missing]', href: expected_facet_query_param
    end
  end

  context 'with min/max but no range segments' do
    let(:facet_field_params) do
      {
        range_queries: [],
        min: 100,
        max: 300
      }
    end

    it "renders a link to fetch distribution info" do
      # need request_url for routing of links generated
      with_request_url '/catalog' do
        load_link = rendered.find(".distribution a.load_distribution[href]")
        expect(load_link).to be_present

        expect(load_link["href"]).to be_present
        params = Rack::Utils.parse_nested_query(load_link["href"].split("?").try(:last))
        expect(params["range_field"]).to eq facet_field.key
        expect(params["range_start"]).to eq facet_field_params[:min].to_s
        expect(params["range_end"]).to eq facet_field_params[:max].to_s
      end
    end
  end

  context 'with open-ended query' do
    let(:selected_max) { 200 }
    let(:data_max) { 300 }

    let(:facet_field) do
      instance_double(
        BlacklightRangeLimit::FacetFieldPresenter,
        key: 'key',
        active?: false,
        collapsed?: false,
        in_modal?: false,
        label: 'My facet field',
        selected_range: nil,
        selected_range_facet_item: Blacklight::Solr::Response::Facets::FacetItem.new(..selected_max),
        missing_facet_item: nil,
        missing_selected?: false,
        min: nil,
        max: nil,
        search_state: Blacklight::SearchState.new({}, nil),
        range_config: BlacklightRangeLimit.default_range_config[:range_config],
        modal_path: nil,
        facet_field: facet_config,
        **facet_field_params,
        **extra_facet_field_params
      )
    end

    let(:facet_field_params) do
      {
        range_queries: [],
        min: 100,
        max: data_max
      }
    end

    # This can be relevant in multi-valued queries, where even though you limited to
    # < 200, some items in search can ALSO have additional values greater than 200, but
    # we don't want to include them in our range buckets.
    it "renders fetch distribution with expressed boundaries taking priority" do
      # need request_url for routing of links generated
      with_request_url '/catalog' do
        load_link = rendered.find(".distribution a.load_distribution[href]")
        expect(load_link).to be_present

        expect(load_link["href"]).to be_present
        params = Rack::Utils.parse_nested_query(load_link["href"].split("?").try(:last))
        expect(params["range_field"]).to eq facet_field.key
        expect(params["range_start"]).to eq facet_field_params[:min].to_s
        expect(params["range_end"]).to eq selected_max.to_s
      end
    end
  end

  context 'with no data to display (e.g., no results page)' do
    let(:facet_field_params) { { min: nil, max: nil, missing_facet_item: nil } }

    it 'does not render the range limit facet' do
      expect(component.render?).to be false
    end
  end
end
