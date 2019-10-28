ENV["RAILS_ENV"] ||= 'test'
require 'rsolr'
require 'engine_cart'
EngineCart.load_application!

require 'rspec/rails'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'webdrivers'

Capybara.javascript_driver = :selenium_chrome_headless

RSpec.configure do |config|
  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!
end
