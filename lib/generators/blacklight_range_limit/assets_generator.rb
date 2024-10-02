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

    class_option :js_file, type: :string, default: "app/javascript/application.js"

    def assets
        #say_status "warning", "Can not find application.css, did not insert our require", :red
      if root.join("config/importmap.rb").exist?
        append_to_file("config/importmap.rb") do
          <<~EOS

            # dependencies of blacklight-range-limit, currently don't seem to be working
            # as vendored importmaps, but instead must be from CDN.
            pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@4.2.0/dist/chart.js"
            pin "@kurkle/color", to: "https://ga.jspm.io/npm:@kurkle/color@0.3.2/dist/color.esm.js"
          EOS
        end
        say_status(:info, "Pinned dependencies in config/importmap.rb")
      else
        say_status(:warn, "Javascript dependency setup not detected so dependencies were not setup")
      end

      if root.join(options[:js_file]).exist?
        append_to_file options[:js_file],
          %Q{import BlacklightRangeLimit from "blacklight-range-limit\"},
          after: /import Blacklight from ['"]blacklight['"].*\n/

        append_to_file options[:js_file], "\nBlacklightRangeLimit.init({onLoadHandler: Blacklight.onLoad });"
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
