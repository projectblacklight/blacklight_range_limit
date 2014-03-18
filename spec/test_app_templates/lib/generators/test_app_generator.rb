require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../test_app_templates", __FILE__)

  # This is only necessary for Rails 3
  def remove_index
    remove_file "public/index.html"
  end

  def run_blacklight_generator
    say_status("warning", "GENERATING BL", :yellow)       

    generate 'blacklight:install', '--devise'
  end

  def run_blacklight_range_limit_generator
    say_status("warning", "GENERATING BL", :yellow)       

    generate 'blacklight_range_limit'
  end
end
