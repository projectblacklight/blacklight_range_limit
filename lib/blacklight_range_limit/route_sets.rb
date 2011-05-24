module BlacklightRangeLimit
  module RouteSets
    protected
    def catalog
      add_routes do |options|
        match 'catalog/range_limit' => 'catalog#range_limit'
      end

      super
    end
  end
end
