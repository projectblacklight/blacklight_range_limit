require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../spec/test_app_templates", __FILE__)

  # While blacklight works with jsbundling-rails (and vite-ruby with layout modification),
  # it's generators can't set it up at present, we hackily do so.
  def run_bl7_jsbundling_fixup
    if File.exist?("package.json") && Blacklight::VERSION.split(".").first == "7"
      say_status("warning", "BlacklightRangeLimit: Blacklight 7.x package.json-based Test App fixup", {color: :yellow})
      generate "blacklight_range_limit:jsbundling_bl7_fixup"
    end
  end

  def run_bl8_jsbundling_fixup
    # BL 8.7.0 doesn't seem to need anything, but BL8 before that the automatic BL
    # install process doesn't do everything we need.
    #
    # By manually triggering the BL8 assets:propshaft generator, we can get what we need
    # for jsbundling, even though it's named confusingly for that, it works in these
    # versions.
    if File.exist?("package.json") && Gem::Requirement.create("~> 8.0", "< 8.7.0").satisfied_by?(Gem::Version.new(Blacklight::VERSION))
      generate "blacklight:assets:propshaft"
    end
  end

  def run_blacklight_generator
    say_status("warning", "GENERATING Blacklight", :yellow)

    generate 'blacklight:install', '--devise'
  end

  def run_bl8_importmaps_fixup
    # In BL8, if we have CSS-bundling rails but ALSO are using importmaps for JS, the BL8 installer
    # gets us a LOT of the way there, but doesn't actually set up importmap pins for JS and needs
    # some fixup. Maybe fixed in BL9?  We fix up here if we are in that situation.
    if Pathname(destination_root).join("config/importmap.rb").exist? && Blacklight::VERSION.split(".").first == "8"
      # BL's importmap setup annoyingly uses a different name for the BL package than their package.json setup
      gsub_file("app/javascript/application.js", 'import Blacklight from "blacklight-frontend";', 'import Blacklight from "blacklight";')

      # these pins copied from BL8 ImportMapsGenerator
      append_to_file 'config/importmap.rb' do
        <<~CONTENT
          pin "@github/auto-complete-element", to: "https://cdn.skypack.dev/@github/auto-complete-element"
          pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.6/dist/umd/popper.min.js"
          pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@#{(defined?(Bootstrap) && Bootstrap::VERSION) || '5.3.2'}/dist/js/bootstrap.js"
        CONTENT
      end
    end
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
      "\n    config.add_facet_field 'pub_date_si', label: 'Publication Date Sort', range: true"
    end
  end
end
