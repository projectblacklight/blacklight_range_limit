require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../spec/test_app_templates", __FILE__)

  # While blacklight works with jsbundling-rails (and vite-ruby with layout modification),
  # it's generators can't set it up at present, we hackily do so.
  def run_jsbundling_bl7_fixup
    if File.exist?("package.json") && Blacklight::VERSION.split(".").first == "7"
      say_status("warning", "BlacklightRangeLimit: Blacklight 7.x package.json-based Test App fixup", {color: :yellow})
      generate "blacklight_range_limit:jsbundling_bl7_fixup"
    end
  end

  def run_blacklight_generator
    say_status("warning", "GENERATING Blacklight", :yellow)

    generate 'blacklight:install', '--devise'
  end

  def run_blacklight_range_limit_generator
    say_status("warning", "GENERATING BlacklightRangeLimit", :yellow)

    generate 'blacklight_range_limit:install'
  end

  def fixtures
    FileUtils.mkdir_p 'spec/fixtures/solr_documents'
    directory '../fixtures/solr_documents', 'spec/fixtures/solr_documents'
  end

  def inject_into_catalog_controller
    inject_into_file 'app/controllers/catalog_controller.rb', after: /config.add_facet_field 'format'.*$/ do
      "\n    config.add_facet_field 'pub_date_si', label: 'Publication Date Sort', **default_range_config"
    end
  end
end
