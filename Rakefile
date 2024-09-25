require 'rake'
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
require 'engine_cart/rake_task'
require 'solr_wrapper'
require 'open3'

task :default => :ci

desc "Run specs"
RSpec::Core::RakeTask.new

def system_with_error_handling(*args)
  Open3.popen3(*args) do |_stdin, stdout, stderr, thread|
    puts stdout.read
    raise "Unable to run #{args.inspect}: #{stderr.read}" unless thread.value.success?
  end
end

def with_solr
  if system('docker compose -v')
    begin
      puts "Starting Solr"
      system_with_error_handling "docker compose up -d solr"
      yield
    ensure
      puts "Stopping Solr"
      system_with_error_handling "docker compose stop solr"
    end
  else
    SolrWrapper.wrap do |solr|
      solr.with_collection do
        yield
      end
    end
  end
end

task :ci do
  with_solr do
    Rake::Task["test:seed"].invoke
    Rake::Task['spec'].invoke
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

    with_solr do
      Rake::Task['test:seed'].invoke

      within_test_app do
        system "bundle exec rails s #{args[:rails_server_args]}"
      end
    end
  end
end
