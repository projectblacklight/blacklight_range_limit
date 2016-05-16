require 'spec_helper'

describe "Blacklight Range Limit" do

  it "should show the range limit facet" do
    visit search_catalog_path
    expect(page).to have_selector 'input.range_begin'
    expect(page).to have_selector 'input.range_end'
    expect(page).to have_selector 'label.sr-only[for="range_pub_date_sort_begin"]', :text => 'Publication Date Sort range begin'
    expect(page).to have_selector 'label.sr-only[for="range_pub_date_sort_end"]', :text => 'Publication Date Sort range end'
    expect(page).to have_button 'Limit'
  end

  it "should provide distribution information" do
    visit search_catalog_path
    click_link 'View distribution'

    expect(page).to have_content("1500 to 1599 0")
    expect(page).to have_content("2000 to 2008 12")
  end

  it "should limit appropriately" do
    visit search_catalog_path
    click_link 'View distribution'
    click_link '2000 to 2008'

    expect(page).to have_content "2000 to 2008 [remove] 12"
  end

  context 'when I18n translation is available' do
    before do
      I18n.backend.store_translations(:en, blacklight: {search: {fields: {facet: {pub_date_sort: 'Publication Date I18n'}}}})
    end

    it 'should render the I18n label' do
      visit search_catalog_path
      click_link 'View distribution'
      click_link '2000 to 2008'

      expect(page).to have_content 'Publication Date I18n'
      expect(page).to_not have_content 'Publication Date Sort'
    end
  end
end

describe "Blacklight Range Limit with configured input labels" do
  before do
    CatalogController.blacklight_config = Blacklight::Configuration.new
    CatalogController.configure_blacklight do |config|
      config.add_facet_field 'pub_date_sort', range: {
        input_label_range_begin: 'from publication date',
        input_label_range_end: 'to publication date',
        maxlength: 6
      }
      config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    end  
  end    
  
  it "should show the range limit facet with configured labels and maxlength" do
    visit '/catalog'
    expect(page).to have_selector 'label.sr-only[for="range_pub_date_sort_begin"]', :text => 'from publication date'
    expect(page).to have_selector 'label.sr-only[for="range_pub_date_sort_end"]', :text => 'to publication date'
    expect(page).to have_selector 'input#range_pub_date_sort_begin[maxlength="6"]'
    expect(page).to have_selector 'input#range_pub_date_sort_end[maxlength="6"]'
  end

end
