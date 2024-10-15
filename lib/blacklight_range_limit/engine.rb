require 'blacklight'
require 'blacklight_range_limit'
require 'rails'

require 'debug'

module BlacklightRangeLimit
  # delegate for easier configability
  def self.config
    Engine.config
  end

  class Engine < Rails::Engine
    config.action_dispatch.rescue_responses.merge!(
      "BlacklightRangeLimit::InvalidRange" => :not_acceptable
    )


    config.using_importmaps = nil
    config.using_importmaps_sprockets = nil

    initializer "blacklight_range_limit.asset_mode_config" do |app|
      # We guess based on what's in the app which is normally good enough,
      # but you can set eg BlacklightRangeLimit.config.using_importmaps directly
      # in your config/application.rb if the guess was not right for your environment.

      if config.using_importmaps.nil?
        config.using_importmaps = begin
          Pathname(Rails.application.root).join("config/importmap.rb").exist? && app.config.respond_to?(:importmap)
        end
      end

      if config.using_importmaps_sprockets.nil?
        config.using_importmaps_sprockets ||= begin
          config.using_importmaps && defined?(Sprockets) && !defined?(Propshaft)
        end
      end
    end

    # TODO:  Config for using_importmaps and
    # move source elsewhere so it's not in asset path with propshaft putting
    # it in public, unless you actually want that?  Only want that if we have propshaft and importmaps?

    # TODO only turn this on if we're supporting sprockets-direct-importmaps combo
    initializer "blacklight_range_limit.assets.precompile" do |app|
      # IF they are using SPROCKETS *and* importmaps directly to engine files, then we
      # need to tell sprockets all our JS files need to be available via HTTP, like
      # so
      if BlacklightRangeLimit.config.using_importmaps_sprockets
        app.config.assets.precompile += ["blacklight-range-limit/index.js"]
      end
    end

    initializer "blacklight_range_limit.importmap", before: "importmap" do |app|
      if BlacklightRangeLimit.config.using_importmaps
        app.config.importmap.paths << Engine.root.join("config/importmap.rb")
      end
    end

    config.before_configuration do
      Blacklight::Configuration::FacetField.prepend BlacklightRangeLimit::FacetFieldConfigOverride
    end
  end
end
