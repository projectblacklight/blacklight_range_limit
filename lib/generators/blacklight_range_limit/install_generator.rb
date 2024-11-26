require 'rails/generators'

module BlacklightRangeLimit
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    class_option :'skip-assets', type: :boolean, default: false, desc: "Skip generation of assets into app"
    class_option :'builder-path', type: :string, default: 'app/models/search_builder.rb', aliases: "-b", desc: "Set the path, relative to Rails root, to the Blacklight app's search builder class"

    def generate_assets
      unless options[:'skip-assets']
        generate 'blacklight_range_limit:assets'
      end
    end

    def install_catalog_controller_mixin
      inject_into_file 'app/controllers/catalog_controller.rb', after: /include Blacklight::Catalog.*$/ do
        "\n  include BlacklightRangeLimit::ControllerOverride\n"
      end
    end

    def install_search_builder
      path = options[:'builder-path']
      if File.exist? path
        inject_into_file path, after: /include Blacklight::Solr::SearchBuilderBehavior.*$/ do
          "\n  include BlacklightRangeLimit::RangeLimitBuilder\n"
        end
      else
        say_status("error", "Unable to find #{path}. You must manually add the 'include BlacklightRangeLimit::RangeLimitBuilder' to your SearchBuilder", :red)
      end
    end

    def install_routing_concern
      route('concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new')
    end

    def add_range_limit_concern_to_catalog
      sentinel = /concerns :searchable.*$/

      inject_into_file 'config/routes.rb', after: sentinel do
        "\n    concerns :range_searchable\n"
      end
    end
  end
end
