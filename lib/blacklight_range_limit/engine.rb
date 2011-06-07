require 'blacklight'
require 'blacklight_range_limit'
require 'rails'

module BlacklightRangeLimit
  class Engine < Rails::Engine
  
    # Do these things in a to_prepare block, to try and make them work
    # in development mode with class-reloading. The trick is we can't
    # be sure if the controllers we're modifying are being reloaded in
    # dev mode, if they are in the BL plugin and haven't been copied to
    # local, they won't be. But we do our best. 
    config.to_prepare do
      BlacklightRangeLimit.inject!

      unless BlacklightRangeLimit.omit_inject[:routes]
        Blacklight::Routes.send(:include, BlacklightRangeLimit::RouteSets)
      end
    end
  end
end
