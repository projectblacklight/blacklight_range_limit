require 'spec_helper'

describe "Blacklight Range Limit" do

  it "should show the range limit facet" do
    visit catalog_index_path
    page.should have_selector 'input.range_begin'
    page.should have_selector 'input.range_end'
    page.should have_selector 'label.sr-only[for="range_pub_date_sort_begin"]', :text => 'Publication Date Sort range begin'
    page.should have_selector 'label.sr-only[for="range_pub_date_sort_end"]', :text => 'Publication Date Sort range end'
    expect(page).to have_css 'input.submit', value: 'Limit'
  end

  it "should provide distribution information" do
    visit catalog_index_path
    click_link 'View distribution'

    page.should have_content("1500 to 1599 0")
    page.should have_content("2000 to 2008 12")
  end

  it "should limit appropriately" do
    visit catalog_index_path
    click_link 'View distribution'
    click_link '2000 to 2008'

    page.should have_content "2000 to 2008 [remove] 12"
  end
end

describe "Blacklight Range Limit with configured input labels" do
  before do
    CatalogController.blacklight_config = Blacklight::Configuration.new
    CatalogController.configure_blacklight do |config|
      config.add_facet_field 'pub_date_sort', :range => {
        :input_label_range_begin => 'from publication date',
        :input_label_range_end => 'to publication date'
      }
      config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    end  
  end    
  
  it "should show the range limit facet" do
    visit '/catalog'
    page.should have_selector 'label.sr-only[for="range_pub_date_sort_begin"]', :text => 'from publication date'
    page.should have_selector 'label.sr-only[for="range_pub_date_sort_end"]', :text => 'to publication date'
  end

end
