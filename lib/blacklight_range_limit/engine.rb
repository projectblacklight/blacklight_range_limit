require 'blacklight'
require 'blacklight_range_limit'
require 'rails'

module BlacklightRangeLimit
  class Engine < Rails::Engine
    initializer "blacklight_range_limit.assets", before: 'assets' do |app|
      if defined? Sprockets
        app.config.assets.precompile << 'blacklight_range_limit.js'
      end
    end

    config.action_dispatch.rescue_responses.merge!(
      "BlacklightRangeLimit::InvalidRange" => :not_acceptable
    )

    config.before_configuration do
      Blacklight::Configuration::FacetField.prepend BlacklightRangeLimit::FacetFieldConfigOverride
    end
  end
end
