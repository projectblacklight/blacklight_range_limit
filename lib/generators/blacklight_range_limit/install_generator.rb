require 'rails/generators'

module BlacklightRangeLimit
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def copy_public_assets
      generate 'blacklight_range_limit:assets'
    end

    def install_catalog_controller_mixin
      inject_into_class 'app/controllers/catalog_controller.rb', CatalogController do
        <<-EOF
          include BlacklightRangeLimit::ControllerOverride
        EOF
      end
    end

    def install_search_builder
      inject_into_file 'app/models/search_builder.rb', after: /include Blacklight::Solr::SearchBuilderBehavior.*$/ do
        <<-EOF

          include BlacklightRangeLimit::RangeLimitBuilder
        EOF
      end
    end

    def install_search_history_controller
     copy_file "search_history_controller.rb", "app/controllers/search_history_controller.rb"
    end

    def install_routing_concern
      route('concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new')
    end

    def add_range_limit_concern_to_catalog
      routing_code = <<-EOF.strip_heredoc

        concerns :range_searchable
      EOF

      sentinel = /concerns :searchable.*$/

      inject_into_file 'config/routes.rb', routing_code, after: sentinel
    end
  end
end
