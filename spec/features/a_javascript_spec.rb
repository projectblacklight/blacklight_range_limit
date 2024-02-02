# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'JavaScript', js: true do
  it 'initializes canvas chart' do
    visit search_catalog_path

    click_button 'Publication Date Sort'
    debugger
    expect(page).to have_css '.flot-base'
  end
  it 'has a View larger modal' do
    visit search_catalog_path

    click_button 'Publication Date Sort'
    sleep(1) # resize is debounced
    click_link 'View larger »'

    within '.modal-body' do
      expect(page).to have_css '.flot-base'
    end
  end

  context 'when assumed boundaries configured' do
    before do
      CatalogController.blacklight_config.facet_fields['pub_date_si'].range_config = {
        assumed_boundaries: 1990...2000
      }
    end

    after do
      CatalogController.blacklight_config.facet_fields['pub_date_si'].range_config = {}
    end

    it 'should show the range limit with set boundaries' do
      visit '/catalog'
      click_button 'Publication Date Sort'
      expect(page).to have_field :range_pub_date_si_begin, with: '1990'
      expect(page).to have_field :range_pub_date_si_end, with: '2000'
    end
  end

  describe '"Unknown" link' do
    context 'when in the facet (e.g. non-xhr)' do
      it 'is displayed' do
        visit search_catalog_path

        click_button 'Publication Date Sort'

        within 'ul.subsection.missing' do
          expect(page).to have_link '[Missing]'
        end
      end
    end

    context 'when in the modal (e.g. via xhr)' do
      it 'is not displayed' do
        visit search_catalog_path

        click_button 'Publication Date Sort'
        sleep(1) # resize is debounced
        click_link 'View larger »'

        within '.modal-body' do
          expect(page).not_to have_css 'ul.subsection.missing'
        end
      end
    end
  end
end
