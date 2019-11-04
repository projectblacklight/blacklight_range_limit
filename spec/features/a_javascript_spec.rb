# frozen_string_literal: true

require 'spec_helper'

describe 'JavaScript', js: true do
  it 'initializes canvas chart' do
    visit search_catalog_path

    within('#facets .navbar') do
      page.find('button.navbar-toggler').click
    end

    click_button 'Publication Date Sort'
    expect(page).to have_css '.flot-base'
  end
end
