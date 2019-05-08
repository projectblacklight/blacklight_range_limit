require 'blacklight'
require 'blacklight_range_limit'
require 'rails'

module BlacklightRangeLimit
  class Engine < Rails::Engine
    # Need to tell asset pipeline to precompile the excanvas
    # we use for IE.
    initializer "blacklight_range_limit.assets", :after => "assets" do
      Rails.application.config.assets.precompile += %w( flot/excanvas.min.js )
    end

    config.action_dispatch.rescue_responses.merge!(
      "BlacklightRangeLimit::InvalidRange" => :not_acceptable
    )
  end
end
