# frozen_string_literal: true

require 'spec_helper'

describe 'JavaScript', js: true do
  context 'when assumed boundaries configured' do
    before do
      CatalogController.blacklight_config.facet_fields['pub_date_sort'].range = {
        assumed_boundaries: [1990, 2000]
      }
    end

    after do
      CatalogController.blacklight_config.facet_fields['pub_date_sort'].range = true
    end

    it 'should show the range limit with set boundaries' do
      visit '/catalog'

      click_link 'Publication Date Sort'
      expect(page).to have_field :range_pub_date_sort_begin, with: '1990'
      expect(page).to have_field :range_pub_date_sort_end, with: '2000'
    end
  end
end
