# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), "lib/blacklight_range_limit/version")

Gem::Specification.new do |s|
  s.name = "blacklight_range_limit"
  s.version = BlacklightRangeLimit::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Jonathan Rochkind"]
  s.email = ["blacklight-development@googlegroups.com"]
  s.homepage    = "http://projectblacklight.org/"
  s.summary = "Blacklight Range Limit plugin"

  s.rubyforge_project = "blacklight"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]


  s.add_dependency "rails", ">= 3.0", "< 5.0"
  s.add_dependency "jquery-rails" # our JS needs jquery_rails
  # for blacklight, we want to allow 5.0.0.preX, as well as all 5.x.y, 
  # but not 6. can't seem to make it do so other than this:
  s.add_dependency "blacklight", ">= 5.0.0.pre4", "< 6"

  s.add_development_dependency "rspec", ">= 2.0"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "capybara"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency 'launchy'
  s.add_development_dependency "jettywrapper", "~> 1.5", ">= 1.5.2"
end
