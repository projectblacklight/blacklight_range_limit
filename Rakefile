require 'rake'

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

require 'engine_cart/rake_task'

EngineCart.fingerprint_proc = EngineCart.rails_fingerprint_proc

require 'solr_wrapper'

task :default => :ci

desc "Run specs"
RSpec::Core::RakeTask.new do |t|

end

task :ci => ['engine_cart:generate'] do
  SolrWrapper.wrap(port: '8983') do |solr|
    solr.with_collection(name: 'blacklight-core', dir: File.join(File.expand_path(File.dirname(__FILE__)), "solr", "conf")) do
      Rake::Task["test:seed"].invoke
      Rake::Task['spec'].invoke
    end
  end
  raise "test failures: #{error}" if error
end

namespace :test do

  desc "Put sample data into solr"
  task :seed => ['engine_cart:generate'] do
    within_test_app do
      ENV['RAILS_ENV'] ||= 'test'
      system "rake blacklight:index:seed"
      system "rake blacklight_range_limit:seed"
    end
  end

end
