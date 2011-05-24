require 'blacklight'
require 'blacklight_range_limit'
require 'rails'

module BlacklightRangeLimit
  class Engine < Rails::Engine
    initializer 'blacklight_range_limit.init', :after => 'blacklight.init' do |app|
      if defined? ActionController::Dispatcher
        ActionController::Dispatcher.to_prepare do
        end
      end
    end
  
    # Do these things in a to_prepare block, to try and make them work
    # in development mode with class-reloading. The trick is we can't
    # be sure if the controllers we're modifying are being reloaded in
    # dev mode, if they are in the BL plugin and haven't been copied to
    # local, they won't be. But we do our best. 
    config.to_prepare do
      BlacklightRangeLimit.inject!
      # Ordinary module over-ride to CatalogController
    end
  end
end
