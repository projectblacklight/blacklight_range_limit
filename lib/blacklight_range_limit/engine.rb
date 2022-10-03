require 'blacklight'
require 'blacklight_range_limit'
require 'rails'

module BlacklightRangeLimit
  class Engine < Rails::Engine
    # Need to tell asset pipeline to precompile the excanvas
    # we use for IE.
    initializer "blacklight_range_limit.assets", :after => "assets" do
      if defined? Sprockets
        Rails.application.config.assets.precompile += %w( flot/excanvas.min.js )
      end
    end

    config.action_dispatch.rescue_responses.merge!(
      "BlacklightRangeLimit::InvalidRange" => :not_acceptable
    )

    config.after_initialize do
      if defined?(::SearchBuilder) # Don't load blacklight config until the blacklight generator has run
        Blacklight::Configuration::FacetField.prepend BlacklightRangeLimit::FacetFieldConfigOverride
      end
    end
  end
end
