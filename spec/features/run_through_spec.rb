# frozen_string_literal: true

require 'spec_helper'

describe 'Run through with javascript', js: true do
  # hacky way to inject browser logs into failure message for failed ones
  after(:each) do |example|
    if example.exception
      browser_logs = page.driver.browser.logs.get(:browser).collect { |log| "#{log.level}: #{log.message}" }

      if browser_logs.present?
        # pretty hacky internal way to get browser logs into long-form failure message
        new_exception = example.exception.class.new("#{example.exception.message}\n\nBrowser console:\n\n#{browser_logs.join("\n")}\n")
        new_exception.set_backtrace(example.exception.backtrace)

        example.display_exception = new_exception
      end
    end
  end


  let(:start_range) { "1900"}
  let(:end_range) { "2100" }

  # capybara tests are slow to setiup, we do a single basic happy path script
  # in one test. We can only check for placement of "canvas"
  # element, not really what's in it.
  it "basically works" do
    visit search_catalog_path

    click_button 'Publication Date Sort'

    within ".facet-limit.blacklight-pub_date_si" do
      expect(page).to have_css('canvas')

      # min/max in actual results are filled in inputs
      expect(find("input#range_pub_date_si_begin").value).to be_present
      expect(find("input#range_pub_date_si_end").value).to be_present

      # expect "missing" facet
      within 'ul.subsection.missing' do
        expect(page).to have_link '[Missing]'
      end

      # fill in some limits and submit
      find("input#range_pub_date_si_begin").set(start_range)
      find("input#range_pub_date_si_end").set(end_range)

      click_button "Apply limit"
    end

    # new page with limit
    expect(page).to have_css(".applied-filter", text: /Publication Date Sort.*#{start_range} to #{end_range}/)

    within ".facet-limit.blacklight-pub_date_si" do
      expect(page).to have_css 'canvas'

      # min/max from specified range
      expect(find("input#range_pub_date_si_begin").value).to eq start_range
      expect(find("input#range_pub_date_si_end").value).to eq end_range
    end
  end

  context 'when assumed boundaries configured' do
    before do
      CatalogController.blacklight_config.facet_fields['pub_date_si'].range_config = {
        assumed_boundaries: start_range.to_i...end_range.to_i
      }
    end

    after do
      CatalogController.blacklight_config.facet_fields['pub_date_si'].range_config = {}
    end

    it 'should show the range limit with set boundaries' do
      visit '/catalog'

      click_button 'Publication Date Sort'
      expect(find("input#range_pub_date_si_begin").value).to be_present
      expect(find("input#range_pub_date_si_end").value).to be_present
    end
  end
end
