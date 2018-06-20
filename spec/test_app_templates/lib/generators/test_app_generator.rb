require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root '../spec/test_app_templates'

  def copy_blacklight_test_app_rake_task
    copy_file "lib/tasks/blacklight_test_app.rake"
  end

  def run_blacklight_generator
    say_status("warning", "GENERATING BL", :yellow)

    generate 'blacklight', '--devise'
  end

  def run_blacklight_range_limit_generator
    say_status("warning", "GENERATING BL", :yellow)

    generate 'blacklight_range_limit'
  end

  # Add favicon.ico to asset path
  # ADD THIS LINE Rails.application.config.assets.precompile += %w( favicon.ico )
  # TO config/assets.rb
  def add_favicon_to_asset_path
    say_status("warning", "ADDING FAVICON TO ASSET PATH", :yellow)

    append_to_file 'config/initializers/assets.rb' do
      'Rails.application.config.assets.precompile += %w( favicon.ico )'
    end
  end
end
