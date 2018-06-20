ENV["RAILS_ENV"] ||= 'test'

require 'rsolr'
require 'engine_cart'
EngineCart.load_application!

require 'rspec/rails'
require 'capybara/rspec'

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
end
