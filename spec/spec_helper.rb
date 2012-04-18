require 'rubygems'
require 'bundler'

Bundler.require :default, :development

require 'blacklight/engine'
require 'rsolr'
require 'rsolr-ext'
require 'capybara/rspec'
Combustion.initialize!

require 'rspec/rails'
require 'capybara/rails'


RSpec.configure do |config|

end

