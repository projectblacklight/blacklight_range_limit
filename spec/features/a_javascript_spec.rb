# frozen_string_literal: true

require 'spec_helper'

describe 'JavaScript', js: true do
  it 'initializes canvas chart' do
    visit search_catalog_path

    click_button 'Publication Date Sort'
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

  describe '"Unknown" link' do
    context 'when in the facet (e.g. non-xhr)' do
      it 'is displayed' do
        visit search_catalog_path

        click_button 'Publication Date Sort'

        within 'ul.subsection.missing' do
          expect(page).to have_link 'Unknown'
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
