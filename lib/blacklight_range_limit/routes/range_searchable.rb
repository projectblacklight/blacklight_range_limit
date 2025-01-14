module BlacklightRangeLimit
  module Routes
    class RangeSearchable
      def initialize(defaults = {})
        @defaults = defaults
      end

      def call(mapper, options = {})
        options = @defaults.merge(options)

        mapper.get 'range_limit', action: 'range_limit'
      end
    end
  end
end
