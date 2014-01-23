module BlacklightRangeLimit
  # This module is monkey-patch included into Blacklight::Routes, so that
  # map_resource will route to catalog#range_limit, for our action
  # that fetches and returns range segments -- that action is
  # also monkey patched into (eg) CatalogController.
  module RouteSets
    extend ActiveSupport::Concern


    included do |klass|
      # Have to add ours BEFORE existing,
      # so catalog/range_limit can take priority over
      # being considered a document ID.
      klass.default_route_sets = [:range_limit] + klass.default_route_sets
    end


    protected


    # Add route for (eg) catalog/range_limit, pointing to the range_limit
    # method we monkey patch into (eg) CatalogController.
    def range_limit(primary_resource)
      add_routes do |options|
        get "#{primary_resource}/range_limit" => "#{primary_resource}#range_limit"
      end
    end
  end
end
