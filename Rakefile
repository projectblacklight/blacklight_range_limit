require 'rake'
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
require 'engine_cart/rake_task'
require 'solr_wrapper'

EngineCart.fingerprint_proc = EngineCart.rails_fingerprint_proc

task :default => :ci

desc "Run specs"
RSpec::Core::RakeTask.new

task ci: ['engine_cart:generate'] do
  SolrWrapper.wrap do |solr|
    solr.with_collection(name: 'blacklight-core', dir: File.join(File.expand_path(File.dirname(__FILE__)), "solr", "conf")) do
      Rake::Task["test:seed"].invoke
      Rake::Task['spec'].invoke
    end
  end
end

namespace :test do
  desc "Put sample data into solr"
  task seed: ['engine_cart:generate'] do
    within_test_app do
      ENV['RAILS_ENV'] ||= 'test'
      system "rake blacklight:index:seed"
      system "rake blacklight_range_limit:seed"
    end
  end
end
