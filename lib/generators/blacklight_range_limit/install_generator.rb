require 'rails/generators'

module BlacklightRangeLimit
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def copy_public_assets
      generate 'blacklight_range_limit:assets'
    end

    def install_catalog_controller_mixin
      inject_into_class 'app/controllers/catalog_controller.rb', CatalogController do
        "\n  include BlacklightRangeLimit::ControllerOverride\n"
      end
    end

    def install_search_builder
      path = 'app/models/search_builder.rb'
      if File.exists? path
        inject_into_file path, after: /include Blacklight::Solr::SearchBuilderBehavior.*$/ do
          "\n  include BlacklightRangeLimit::RangeLimitBuilder\n"
        end
      else
        say_status("error", "Unable to find #{path}. You must manually add the 'include BlacklightRangeLimit::RangeLimitBuilder' to your SearchBuilder", :red)
      end
    end

    def install_search_history_controller
     copy_file "search_history_controller.rb", "app/controllers/search_history_controller.rb"
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
