require 'rails/generators'

# FOR CI: NOT INTENDED FOR REAL APP
#
# We hackily get a BL7 app into a state jsbundling-rails/esbuild will work with it.
#
# May not work with all permutations of real-world apps, may do some hacks that get CI
# to run but would break a real app!

module BlacklightRangeLimit
  class JsbundlingBl7FixupGenerator < Rails::Generators::Base
    source_root File.expand_path("../../../../../spec/test_app_templates", __FILE__)

    def guard_test_app_only
      unless Rails.application.class.name == "Internal::Application"
        raise "For safety, this generator can only be run in a test app, with app name 'test', not '#{Rails.application.name}'"
      end
    end

    def add_blacklight_dependencies_to_package_json
      # there is no blacklight 7.39.0, maybe a mistake...
      bl_frontend_version = (Blacklight::VERSION == "7.39.0" ? "7.38.0" : Blacklight::VERSION)

      run "yarn add --non-interactive blacklight-frontend@#{bl_frontend_version}", abort_on_failure: true

      # while blacklight7 may work with bootstrap 5, we'll test with 4 for now
      run "yarn add --non-interactive bootstrap@^4.1.0", abort_on_failure: true
      run "yarn add --non-interactive popper.js@^1.16.0", abort_on_failure: true
    end

    # NOTE this is why you don't want to run this in a real app!!!
    def remove_default_stimulus_code
      # Due to a bug or something, import of stimulus will cause a problem with esbuild,
      # Blacklight layout's default application.js script tag lacking type=module
      # SEE: https://gist.github.com/pch/fe276b29ba037bdaeaa525932478ca18

      remove_dir (BlacklightRangeLimit.root + "app/javascript/controllers").to_s
    end

    def add_blacklight7_esm_imports
      js_dir = BlacklightRangeLimit.root + "app/javascript"
      app_js_file = dir + "application.js"

      unless app_js_file.exist?
        raise "Cannot find file to set up at #{app_js_file}"
      end

      # Need to setup some things BEFORE actual blacklight imports, to work right
      create_file (js_dir + "blacklight_dependency_setup.js") do
        <<~EOS
          import $ from 'jquery'
          window.jQuery = window.$ = $

          // Bootstrap 4 also needs Popper, and needs it installed in window.Popper
          import Popper from 'popper.js';
          window.Popper = Popper;
        EOS
      end

      append_to_file app_js_file do
        <<~EOS
          import "bootstrap";
          import "./blacklight_dependency_setup.js"
          import 'blacklight-frontend/app/javascripts/blacklight/blacklight'
        EOS
      end
    end
  end
end
