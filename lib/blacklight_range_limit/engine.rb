require 'blacklight'
require 'blacklight_range_limit'
require 'rails'

module BlacklightRangeLimit
  class Engine < Rails::Engine
    config.action_dispatch.rescue_responses.merge!(
      "BlacklightRangeLimit::InvalidRange" => :not_acceptable
    )

    # TODO:  Config for engine_importmaps and engine_importmaps_sprockets
    # move source elsewhere so it's not in asset path with propshaft putting
    # it in public, unless you actually want that?

    # TODO only turn this on if we're supporting sprockets-direct-importmaps combo
    initializer "blacklight_range_limit.assets.precompile" do |app|
      # IF they are using SPROCKETS *and* importmaps directly to engine files, then we
      # need to tell sprockets all our JS files need to be available via HTTP, like
      # so
      app.config.assets.precompile += ["blacklight-range-limit/index.js"]
    end

    initializer "blacklight_range_limit.importmap", before: "importmap" do |app|
      # IF they are wanting to use direct importmaps to enginefiles, we need to
      # tell them to look for our stuff here...

      #if config.importmaps
        # we do need this, not sure why thought it would be default for rails
        if app.config.respond_to?(:importmap)
          app.config.importmap.paths << Engine.root.join("config/importmap.rb")
        #app.config.importmap.cache_sweepers << Engine.root.join("javascript-package")
        end
      #end
    end

    config.before_configuration do
      Blacklight::Configuration::FacetField.prepend BlacklightRangeLimit::FacetFieldConfigOverride
    end
  end
end
