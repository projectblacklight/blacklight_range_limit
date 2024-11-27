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

      # expect expandable limits
      find("summary", text: "Range List").click
      expect(page).to have_css("details ul.facet-values li")

      # expect "missing" facet
      within 'ul.missing' do
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

      # expect expandable limits
      find("summary", text: "Range List").click
      expect(page).to have_css("details ul.facet-values li")
    end
  end

  context "for single dates" do
    it "does not show chart or facet list" do
      visit search_catalog_path

      click_button 'Publication Date Sort'
      last_date = nil
      within ".facet-limit.blacklight-pub_date_si" do
        last_date = find("input#range_pub_date_si_begin").value

        find("input#range_pub_date_si_begin").set(last_date)
        find("input#range_pub_date_si_end").set(last_date)
        click_button "Apply limit"
      end

      expect(page).to have_css(".applied-filter", text: /Publication Date Sort.*#{last_date}/)
      within ".facet-limit.blacklight-pub_date_si" do
        expect(page).not_to have_css 'canvas'
        expect(page).not_to have_css 'details'
      end
    end
  end

  context "open-ended range" do
    it "can search" do
      visit search_catalog_path

      click_button 'Publication Date Sort'

      within ".facet-limit.blacklight-pub_date_si" do
        find("input#range_pub_date_si_begin").set("")
        find("input#range_pub_date_si_end").set(end_range)
        click_button "Apply limit"
      end

      expect(page).to have_css(".applied-filter", text: /Publication Date Sort +to #{end_range}/)
      expect(page).not_to have_text("No entries found")
      expect(page).to have_css(".document")

      within ".facet-limit.blacklight-pub_date_si" do
        # expect expandable limits
        find("summary", text: "Range List").click
        expect(page).to have_css("details ul.facet-values li")
      end
    end
  end

  context "submitted with empty boundaries" do
    it "does not apply filter" do
      visit search_catalog_path

      click_button 'Publication Date Sort'

      within ".facet-limit.blacklight-pub_date_si" do
        find("input#range_pub_date_si_begin").set("")
        find("input#range_pub_date_si_end").set("")
        click_button "Apply limit"
      end
      expect(page).not_to have_css(".applied-filter")

      click_button 'Publication Date Sort'
      within ".facet-limit.blacklight-pub_date_si" do
        expect(page).not_to have_css(".selected")
      end
    end
  end

  context 'when assumed boundaries configured' do
    around do |example|
      original = CatalogController.blacklight_config.facet_fields['pub_date_si'].range_config
      CatalogController.blacklight_config.facet_fields['pub_date_si'].range_config = original.merge({
         :assumed_boundaries=>1900...2100,
      })

      example.run

      CatalogController.blacklight_config.facet_fields['pub_date_si'].range_config = original
    end

    it 'should show the range limit with set boundaries' do
      visit '/catalog'

      click_button 'Publication Date Sort'
      expect(find("input#range_pub_date_si_begin").value).to be_present
      expect(find("input#range_pub_date_si_end").value).to be_present
    end
  end

  context 'when missing facet item is configured not to show' do
    around do |example|
      original = CatalogController.blacklight_config.facet_fields['pub_date_si'].range_config
      CatalogController.blacklight_config.facet_fields['pub_date_si'].range_config = original.merge({
        show_missing_link: false
      })

      example.run

      CatalogController.blacklight_config.facet_fields['pub_date_si'].range_config = original
    end

    it 'should not show the missing facet item' do
      visit search_catalog_path

      within ".facet-limit.blacklight-pub_date_si" do
        expect(page).not_to have_css("ul.missing")
      end
    end
  end

  context "Range Limit text facets" do
    # Make sure it works with strict permitted params
    around do |example|
      original = ActionController::Parameters.action_on_unpermitted_parameters
      ActionController::Parameters.action_on_unpermitted_parameters = :raise

      example.run

      ActionController::Parameters.action_on_unpermitted_parameters = original
    end

    it "work with strict permitted params" do
      visit search_catalog_path

      click_button 'Publication Date Sort'

      from_val, to_val = nil, nil
      within ".facet-limit.blacklight-pub_date_si" do
        find("summary", text: "Range List").click

        facet_link = first(".facet-values li a")
        from_val = facet_link.find("span[data-blrl-begin]")["data-blrl-begin"]
        to_val = facet_link.find("span[data-blrl-end]")["data-blrl-end"]

        facet_link.click
      end

      expect(page).to have_css(".applied-filter", text: /Publication Date Sort.*#{from_val} to #{to_val}/)
    end
  end
end
