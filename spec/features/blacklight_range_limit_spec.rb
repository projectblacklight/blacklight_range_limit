require 'spec_helper'

describe "Blacklight Range Limit" do
  before do
    CatalogController.blacklight_config = Blacklight::Configuration.new
    CatalogController.configure_blacklight do |config|
      config.add_facet_field 'pub_date_sort', :range => true
      config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    end

  end

  it "should show the range limit facet" do
    visit '/catalog?q='
    page.should have_selector 'input.range_begin'
    page.should have_selector 'input.range_end'
  end

  it "should provide distribution information" do
    visit '/catalog?q='
    click_link 'View distribution'

    page.should have_content("1941 to 1944 (1)")
    page.should have_content("2005 to 2008 (7)")
  end

  it "should limit appropriately" do
    visit '/catalog?q='
    click_link 'View distribution'
    click_link '1941 to 1944'

    page.should have_content "1941 to 1944 (1) [remove]"
  end
end
