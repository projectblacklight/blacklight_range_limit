require 'rubygems'
require 'bundler/setup'

ENV["RAILS_ENV"] ||= 'test'

require 'rsolr'

require File.expand_path("config/environment", ENV['RAILS_ROOT'] || File.expand_path("../internal", __FILE__))


require 'rspec/rails'
require 'capybara/rspec'


RSpec.configure do |config|

end

