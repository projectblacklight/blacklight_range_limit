# frozen_string_literal: true

source 'https://rubygems.org'

# Please see blacklight.gemspec for dependency information.
gemspec path: File.expand_path('..', __FILE__)

group :test do
  gem 'activerecord-jdbcsqlite3-adapter', platform: :jruby
end

# While gemspec allows BL8 and some people are using BL8... the build
# has never actually passed on BL8 yet. We may choose to run tests on
# a blacklight version other than the latest allowed by gemspec, to get
# tests to pass, or to test on older BL still supported here.
if ENV['BLACKLIGHT_VERSION']
  if ENV['BLACKLIGHT_VERSION'].include?("://")
    gem "blacklight", git: ENV['BLACKLIGHT_VERSION']
  else
    gem "blacklight", ENV['BLACKLIGHT_VERSION']
  end
end

# BEGIN ENGINE_CART BLOCK
# engine_cart: 2.5.0
# engine_cart stanza: 2.5.0
# the below comes from engine_cart, a gem used to test this Rails engine gem in the context of a Rails app.
file = File.expand_path('Gemfile', ENV['ENGINE_CART_DESTINATION'] || ENV['RAILS_ROOT'] || File.expand_path('.internal_test_app', File.dirname(__FILE__)))
if File.exist?(file)
  begin
    eval_gemfile file
  rescue Bundler::GemfileError => e
    Bundler.ui.warn '[EngineCart] Skipping Rails application dependencies:'
    Bundler.ui.warn e.message
  end
else
  Bundler.ui.warn "[EngineCart] Unable to find test application dependencies in #{file}, using placeholder dependencies"

  if ENV['RAILS_VERSION']
    if ENV['RAILS_VERSION'] == 'edge'
      gem 'rails', github: 'rails/rails'
      ENV['ENGINE_CART_RAILS_OPTIONS'] = '--edge --skip-turbolinks'
    else
      gem 'rails', ENV['RAILS_VERSION']
    end
  end
end
# END ENGINE_CART BLOCK

eval_gemfile File.expand_path("spec/test_app_templates/Gemfile.extra", File.dirname(__FILE__))
