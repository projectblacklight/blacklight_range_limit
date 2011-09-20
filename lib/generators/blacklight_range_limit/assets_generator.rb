# Copy BlacklightRangeLimit assets to public folder in current app. 
# If you want to do this on application startup, you can
# add this next line to your one of your environment files --
# generally you'd only want to do this in 'development', and can
# add it to environments/development.rb:
#       require File.join(BlacklightRangeLimit.root, "lib", "generators", "blacklight", "assets_generator.rb")
#       BlacklightRangeLimit::AssetsGenerator.start(["--force", "--quiet"])


# Need the requires here so we can call the generator from environment.rb
# as suggested above. 
require 'rails/generators'
require 'rails/generators/base'
module BlacklightRangeLimit
  class AssetsGenerator < Rails::Generators::Base
    source_root File.join(BlacklightRangeLimit::Engine.root, 'app', 'assets')

    def assets
      if BlacklightRangeLimit.use_asset_pipeline?
        insert_into_file "app/assets/stylesheets/application.css", :before => "*/" do
%q{
 *
 * Used by blacklight_range_limit
 *= require  'blacklight_range_limit/blacklight_range_limit'
 *         
}
        end

        insert_into_file "app/assets/javascripts/application.js", :after => "//= require jquery" do
%q{

// Used by blacklight_range_limit
//= require 'flot/jquery.flot.js'
//= require 'flot/jquery.flot.selection.js'
// You can elmiminate one or both of these if you don't want their functionality
//= require 'blacklight_range_limit/range_limit_slider'
//= require 'blacklight_range_limit/range_limit_distro_facets'

}          
        end
      else
        directory("stylesheets/blacklight_range_limit", "public/stylesheets")        
        directory("javascripts/blacklight_range_limit", "public/javascripts")
        directory("javascripts/flot", "public/javascripts/flot")
      end
    end
    


  end
end

