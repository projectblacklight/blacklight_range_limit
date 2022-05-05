module BlacklightRangeLimit
  # Override the upstream normalize method to inject range limit defaults
  module FacetFieldConfigOverride
    def normalize!(*args)
      normalize_range! if range

      super
    end

    def normalize_range!
      self.had_existing_component_configuration = component.present?

      if range.is_a? Hash
        self.range_config = range
        self.range = true
      end

      if range_config
        self.range_config = range_config.reverse_merge(BlacklightRangeLimit.default_range_config[:range_config])
      end

      @table.reverse_merge!(BlacklightRangeLimit.default_range_config)
    end
  end
end
