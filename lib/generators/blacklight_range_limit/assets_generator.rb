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
      append_to_file 'app/assets/config/manifest.js', "\n//= link blacklight_range_limit/manifest.js"
      application_css = Dir["app/assets/stylesheets/application{.css,.scss,.css.scss}"].first

      if application_css

        insert_into_file application_css, :before => "*/" do
%q{
 *
 * Used by blacklight_range_limit
 *= require  'blacklight_range_limit'
 *
}
        end
      else
        say_status "warning", "Can not find application.css, did not insert our require", :red
      end

      if defined?(Importmap)
        run 'bin/importmap pin jquery'
        append_to_file "app/javascript/application.js" do
          <<~CONTENT
            import jQuery from "jquery"
            window.jQuery = jQuery
            window.$ = jQuery
            import BlacklightRangeLimit from "blacklight_range_limit"
            Blacklight.onLoad(() => BlacklightRangeLimit.initialize())
          CONTENT
        end
      else
        append_to_file "app/assets/javascripts/application.js" do
          <<~CONTENT
            // For blacklight_range_limit built-in JS, if you don't want it you don't need
            // this:
            //= require 'blacklight_range_limit'
          CONTENT
        end
      end
    end
  end
end
