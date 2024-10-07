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

    # for vite-ruby you may set to eg 'app/frontend/entrypoints/application.js'
    class_option :js_file, type: :string, default: "app/javascript/application.js"

    def add_to_package_json
      # for apps using jsbundling_rails, vite-ruby, etc.
      if root.join("package.json").exist?
        say_status "info", "Adding blacklight-range-limit to package.json", :blue

        if ENV['CI']
          run "yarn add blacklight-range-limit@file:#{BlacklightRangeLimit::Engine.root}", abort_on_failure: true
        else
          # are we actually going to release one-to-one? Maybe just matching major
          # version would be enough?
          run "yarn add blacklight-range-limit@^#{BlacklightRangeLimit::VERSION.split(".").first}.0.0", abort_on_failure: true
        end
      else
        say_status "info", "No package.json, not adding blacklight-range-limit npm package", :blue
      end
    end

    def dependencies_to_importmap_rb
     if root.join("config/importmap.rb").exist?
        append_to_file("config/importmap.rb") do
          # We'll want to update these version numbers periodically in source here, no other way to do it?
          # And generated apps will have to manually update them too?
          <<~EOS
            # chart.js is dependency of blacklight-range-limit, currently is not working
            # as vendored importmaps, but instead must be pinned to CDN. You may want to update
            # versions perioidically.
            pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@4.2.0/dist/chart.js"
            # single dependency of chart.js:
            pin "@kurkle/color", to: "https://ga.jspm.io/npm:@kurkle/color@0.3.2/dist/color.esm.js"
          EOS
        end
        say_status(:info, "Pinned dependencies in config/importmap.rb", :blue)
      else
        say_status(:info, "no config/importmap.rb, so did not pin JS dependencies for blacklight-range-limit there", :yellow)
      end
    end


    def import_and_start_in_application_js
      if root.join(options[:js_file]).exist?
        js_file_path = root.join(options[:js_file]).to_s

        append_to_file js_file_path do
          <<~EOS

            import BlacklightRangeLimit from "blacklight-range-limit";
            BlacklightRangeLimit.init({onLoadHandler: Blacklight.onLoad });
          EOS
        end
      else
        say_status(:warn, "No file detected at #{options[:js_file]} so JS setup not added")
      end
    end

    private

    def root
      @root ||= Pathname(destination_root)
    end
  end
end
