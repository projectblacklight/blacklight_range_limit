require 'blacklight'
require 'blacklight_range_limit'
require 'rails'

module BlacklightRangeLimit
  class Engine < Rails::Engine
    config.action_dispatch.rescue_responses.merge!(
      "BlacklightRangeLimit::InvalidRange" => :not_acceptable
    )

    config.before_configuration do
      Blacklight::Configuration::FacetField.prepend BlacklightRangeLimit::FacetFieldConfigOverride
    end

    initializer 'blacklight_range_limit.assets', before: 'assets' do |app|
      app.config.assets.precompile << 'blacklight_range_limit/blacklight_range_limit.esm.js'
    end

    initializer 'blacklight_range_limit.importmap', before: 'importmap' do |app|
      app.config.importmap.paths << Engine.root.join('config/importmap.rb') if app.config.respond_to?(:importmap)
    end
  end
end
