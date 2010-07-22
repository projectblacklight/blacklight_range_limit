require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'


desc 'Generate documentation for the blacklight_range_limit plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'BlacklightRangeLimit'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "blacklight_range_limit"    
    gemspec.summary = "Add integer range limit/profile to a Blacklight app"
    gemspec.description = "Add integer range limit/profile to a Blacklight app"
    gemspec.email = "jonathan@dnil.net"
    gemspec.homepage = "http://github.com/projectblacklight/blacklight_range_limit"
    gemspec.authors = ["Jonathan Rochkind"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

