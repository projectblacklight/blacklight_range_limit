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
end
