module BlacklightRangeLimit
  module Routes
    class RangeSearchable
      def initialize(defaults = {})
        @defaults = defaults
      end

      def call(mapper, options = {})
        options = @defaults.merge(options)

        mapper.get 'range_limit', action: 'range_limit'
        mapper.get 'range_limit_panel/:id', action: 'range_limit_panel'
      end
    end
  end
end
