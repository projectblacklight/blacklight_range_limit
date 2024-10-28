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
      # there is no blacklight 7.39.0 or 7.40.0 makes it hard for us to know what version to
      # generate here, I guess we'll try generating an open range like "^7.0.0"?

      # while blacklight7 may work with bootstrap 5, we'll test with 4 for now, and popper 1.x that goes with it
      run %{yarn add --non-interactive
              blacklight-frontend@^#{Blacklight::VERSION.split(".").first}.0.0
              bootstrap@^4.1.0
              popper.js@^1.16.0}.squish, abort_on_failure: true
    end

    # NOTE this is why you don't want to run this in a real app!!!
    def remove_default_stimulus_code
      # Due to a bug or something, import of stimulus will cause a problem with
      # esbuild, in the presence of Blacklight layout's default application.js
      # script tag lacking type=module
      #
      # generated BL app isn't using this stuff, we will just remove the include
      #
      # SEE: https://gist.github.com/pch/fe276b29ba037bdaeaa525932478ca18

      gsub_file("app/javascript/application.js", %r{^ *import +["']\./controllers.*$}, '')
    end

    def add_blacklight7_esm_imports
      js_dir = "app/javascript"
      app_js_file = js_dir + "/application.js"

      unless Pathname(app_js_file).exist?
        raise "Cannot find file to set up at #{app_js_file}"
      end

      # Need to setup some things BEFORE actual blacklight imports, to work right
      create_file (js_dir + "/blacklight_dependency_setup.js") do
        <<~EOS
          // Making JQuery from ESM available to Blacklight 7 and Bootstrap 4 that want
          // it in window globals.
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

          //import 'blacklight-frontend/app/assets/javascripts/blacklight/blacklight';
          // for some reason we need these all like this to work, can we figure out why?

          import 'blacklight-frontend/app/javascript/blacklight/core';
          import 'blacklight-frontend/app/javascript/blacklight/bookmark_toggle';
          import 'blacklight-frontend/app/javascript/blacklight/button_focus';
          import 'blacklight-frontend/app/javascript/blacklight/checkbox_submit';
          import 'blacklight-frontend/app/javascript/blacklight/facet_load';
          import 'blacklight-frontend/app/javascript/blacklight/modal';
          import 'blacklight-frontend/app/javascript/blacklight/search_context';
        EOS
      end
    end

    def add_blacklight7_sass_esm_import
      # only if we're using propshaft and not sprockets: We are using cssbundling-rails with
      # sass, and we need to add a sass import from blacklight npm package -- that BL7 geenrator
      # didn't know how to do.  (BL8 generator prob does!)
      if !defined?(Sprockets) && defined?(Propshaft)
        append_to_file 'app/assets/stylesheets/application.bootstrap.scss' do
          <<~CONTENT
            @import "blacklight-frontend/app/assets/stylesheets/blacklight/blacklight";
          CONTENT
        end
      end
    end
  end
end
