# frozen_string_literal: true

require 'spec_helper'

describe 'JavaScript', js: true do
  it 'initializes canvas chart' do
    visit search_catalog_path
    click_link 'Publication Date'
    expect(page).to have_css '.flot-base'
  end
end
