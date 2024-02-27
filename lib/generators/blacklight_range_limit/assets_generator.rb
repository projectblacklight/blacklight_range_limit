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

    def copy_styles
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
    end

    def assets
      if using_importmap?
        pin_javascript_dependencies
        import_javascript
      else
        install_sprockets_dependencies
      end
    end


    private

    def root
      @root ||= Pathname(destination_root)
    end

    def using_importmap?
      @using_importmap ||= root.join('config/importmap.rb').exist?
    end

    def pin_javascript_dependencies
      append_to_file 'config/importmap.rb', <<~RUBY
        pin "jquery", to: "https://cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.js"
      RUBY
    end

    def import_javascript
      append_to_file 'app/javascript/application.js', <<~JS
       import "jquery"
       import "blacklight_range_limit"
      JS

      append_to_file 'app/assets/config/manifest.js' do
        <<~CONTENT
          //= link blacklight_range_limit/manifest.js
        CONTENT
      end
    end

    # NOTE: This is expected to fail in Rails 7.1+
    def install_sprockets_dependencies
      append_to_file "app/assets/javascripts/application.js" do
%q{

// For blacklight_range_limit built-in JS, if you don't want it you don't need
// this:
//= require 'blacklight_range_limit'

}
      end
    end
  end
end
