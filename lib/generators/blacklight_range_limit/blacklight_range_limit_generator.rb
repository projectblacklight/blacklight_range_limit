require 'rails/generators'

class BlacklightRangeLimitGenerator < Rails::Generators::Base
  def run_install_generator
    say "`rails g blacklight_range_limit` is deprecated; use `rails g blacklight_range_limit:install` instead", :red
    generate "blacklight_range_limit:install"
  end
end
