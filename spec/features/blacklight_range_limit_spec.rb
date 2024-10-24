require 'spec_helper'

describe "Blacklight Range Limit" do

  it "should show the range limit facet" do
    visit search_catalog_path
    expect(page).to have_selector 'input.range_begin'
    expect(page).to have_selector 'input.range_end'
    expect(page).to have_selector 'label[for="range_pub_date_si_begin"]', :text => I18n.t("blacklight.range_limit.range_begin_short")
    expect(page).to have_selector 'label[for="range_pub_date_si_end"]', :text => I18n.t("blacklight.range_limit.range_end_short")
    expect(page).to have_button 'Apply'
  end

  it "should provide distribution information" do
    visit search_catalog_path
    click_link 'View distribution'
    expect(page).to have_selector('a.facet-select', text: "1500 to 1599")
    expect(page.find('a.facet-select', text: "1500 to 1599").ancestor('li')).to have_selector('span.facet-count', text: "0")
    expect(page).to have_selector('a.facet-select', text: "2000 to 2008")
    expect(page.find('a.facet-select', text: "2000 to 2008").ancestor('li')).to have_selector('span.facet-count', text: "12")
  end

  it "should limit appropriately" do
    visit search_catalog_path
    click_link 'View distribution'
    click_link '2000 to 2008'

    within '.blacklight-pub_date_si' do
      # depending on version of chrome driver, the 'x' may or may not show up
      # here before [remove]
      expect(page).to have_content /2000 to 2008.\[remove\]12/
    end

    within '.constraints-container'  do
      expect(page).to have_content '2000 to 2008'
    end

    expect(page).to have_content '1 - 10 of 12'
  end

  it "should not include page parameter" do
    visit search_catalog_path(page: 2)
    click_link 'View distribution'
    click_link '2000 to 2008'
    click_button 'Apply', match: :first
    expect(page.current_url).not_to include('page')
    expect(page.current_url).not_to include('commit')
  end

  context 'when I18n translation is available' do
    before do
      I18n.backend.store_translations(:en, blacklight: {search: {fields: {facet: {pub_date_si: 'Publication Date I18n'}}}})
    end

    after do
      I18n.backend.store_translations(:en, blacklight: {search: {fields: {facet: {pub_date_si: 'Publication Date Sort'}}}})
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
      config.add_facet_field 'pub_date_si', **CatalogController.default_range_config, range_config: {
        input_label_range_begin: 'from publication date',
        input_label_range_end: 'to publication date',
      }
      config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    end
  end

  it "should show the range limit facet with configured labels" do
    visit '/catalog'
    expect(page).to have_selector 'label[for="range_pub_date_si_begin"]', :text => I18n.t("blacklight.range_limit.range_begin_short")
    expect(page).to have_selector 'label[for="range_pub_date_si_end"]', :text => I18n.t("blacklight.range_limit.range_end_short")

    expect(page).to have_selector 'input#range_pub_date_si_begin'
    expect(page).to have_selector 'input#range_pub_date_si_end'
  end

end
