source 'https://rubygems.org'

gemspec

file = File.expand_path("Gemfile", ENV['ENGINE_CART_DESTINATION'] || ENV['RAILS_ROOT'] || File.expand_path("../spec/internal", __FILE__))
if File.exists?(file)
  puts "Loading #{file} ..." if $DEBUG # `ruby -d` or `bundle -v`
  instance_eval File.read(file)
else
  gem 'rails', ENV['RAILS_VERSION'] if ENV['RAILS_VERSION']

  if ENV['RAILS_VERSION'] and ENV['RAILS_VERSION'] =~ /^4.2/
    gem 'responders', "~> 2.0"
    gem 'sass-rails', ">= 5.0"
  else
    gem 'sass-rails', "< 5.0"
  end
end

# I'm sorry, this is harsh and I think ought to be done some other way with
# engine_cart, but I don't understand how or what's going on, and this
# is all I could to avoid:
# undefined method `type' for .focus:Sass::Selector::Class
#         (in .../blacklight_range_limit/spec/internal/app/assets/stylesheets/blacklight.css.scss)
gem 'sass', "~> 3.4"