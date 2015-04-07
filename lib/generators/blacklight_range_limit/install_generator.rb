require 'rails/generators'

module BlacklightRangeLimit
  class InstallGenerator < Rails::Generators::Base
    def copy_public_assets
      generate "blacklight_range_limit:assets"
    end
  end
end
