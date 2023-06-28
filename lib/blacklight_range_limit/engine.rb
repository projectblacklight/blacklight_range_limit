require 'blacklight'
require 'blacklight_range_limit'
require 'rails'

module BlacklightRangeLimit
  class Engine < Rails::Engine
    config.action_dispatch.rescue_responses.merge!(
      "BlacklightRangeLimit::InvalidRange" => :not_acceptable
    )
    config.before_eager_load do
      ActiveSupport::Reloader.to_prepare do
        Blacklight::Configuration::FacetField.prepend BlacklightRangeLimit::FacetFieldConfigOverride
      end
    end
  end
end
