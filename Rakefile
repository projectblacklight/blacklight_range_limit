require 'rake'
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
require 'engine_cart/rake_task'
require 'solr_wrapper'

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

  desc 'Run Solr and Blacklight for interactive development'
  task :server, [:rails_server_args] do |_t, args|
    if File.exist? EngineCart.destination
      within_test_app do
        system "bundle update"
      end
    else
      Rake::Task['engine_cart:generate'].invoke
    end

    SolrWrapper.wrap(port: '8983') do |solr|
      solr.with_collection(name: 'blacklight-core', dir: File.join(File.expand_path(File.dirname(__FILE__)), "solr", "conf")) do
        Rake::Task['test:seed'].invoke

        within_test_app do
          system "bundle exec rails s #{args[:rails_server_args]}"
        end
      end
    end
  end
end
