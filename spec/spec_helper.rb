require 'rubygems'
require 'bundler'

Bundler.require :default, :development

require 'blacklight/engine'
require 'rsolr'
require 'capybara/rspec'
Combustion.initialize!

require 'rspec/rails'
require 'capybara/rails'


RSpec.configure do |config|

end

