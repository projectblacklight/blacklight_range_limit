require 'rubygems'
require 'bundler/setup'

ENV["RAILS_ENV"] ||= 'test'

require 'rsolr'

require 'engine_cart'
EngineCart.load_application!

require 'rspec/rails'
require 'capybara/rspec'


RSpec.configure do |config|

end

