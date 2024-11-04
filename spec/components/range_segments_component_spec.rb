require 'spec_helper'

RSpec.describe BlacklightRangeLimit::RangeSegmentsComponent, type: :component do
  subject(:component) do
    described_class.new(facet_field: facet_field)
  end

  let(:raw_rendered) { render_inline(component) }

  let(:rendered) do
    Capybara::Node::Simple.new(raw_rendered)
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
      search_state: Blacklight::SearchState.new({}, nil),
      range_config: {},
      modal_path: nil,
      facet_field: facet_config,
      **extra_facet_field_params
    )
  end

  let(:facet_config) do
    Blacklight::Configuration::FacetField.new(key: 'key', item_presenter: BlacklightRangeLimit::FacetItemPresenter)
  end


  let(:extra_facet_field_params) do
    {
      range_queries: [
        OpenStruct.new(value: 100..199, hits: 5),
        OpenStruct.new(value: 200..300, hits: 3)
      ],
      min: 100,
      max: 300,
    }
  end

  # This is JS api and should ideally not be changed without major version
  it "renders list with expected data attributes for JS" do
    # <span class="from" data-blrl-begin="%{begin_value}">%{begin}</span> to <span class="to" data-blrl-end="%{end_value}">%{end}</span>'
    list_items = rendered.all("ul.facet-values li")
    expect(list_items.count).to eq 2

    expect(list_items.first).to have_selector("span.from[data-blrl-begin=100]")
    expect(list_items.first).to have_selector("span.to[data-blrl-end=199]")
    expect(list_items.first).to have_selector("span.facet-count", text: 5)

    expect(list_items[1]).to have_selector("span.from[data-blrl-begin=200]")
    expect(list_items[1]).to have_selector("span.to[data-blrl-end=300]")
    expect(list_items[1]).to have_selector("span.facet-count", text: 3)
  end
end
