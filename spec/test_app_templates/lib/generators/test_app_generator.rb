require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../spec/test_app_templates", __FILE__)

  # This is only necessary for Rails 3
  def remove_index
    remove_file "public/index.html"
  end

  def run_blacklight_generator
    say_status("warning", "GENERATING BL", :yellow)

    generate 'blacklight:install', '--devise'
  end

  def run_blacklight_range_limit_generator
    say_status("warning", "GENERATING BL", :yellow)

    generate 'blacklight_range_limit:install'
  end

  def fixtures
    FileUtils.mkdir_p 'spec/fixtures/solr_documents'
    directory '../fixtures/solr_documents', 'spec/fixtures/solr_documents'
  end

  def inject_into_catalog_controller
    inject_into_file 'app/controllers/catalog_controller.rb', after: /config.add_facet_field 'format'.*$/ do
      "\n    config.add_facet_field 'pub_date_si', label: 'Publication Date Sort', range: true"
    end
  end
end
