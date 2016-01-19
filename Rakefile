require 'rake'


require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

require 'engine_cart/rake_task'

EngineCart.fingerprint_proc = EngineCart.rails_fingerprint_proc

ZIP_URL = "https://github.com/projectblacklight/blacklight-jetty/archive/v4.10.4.zip"

require 'jettywrapper'

task :default => :ci

desc "Run specs"
RSpec::Core::RakeTask.new do |t|

end

task :ci => ['jetty:clean', 'engine_cart:generate'] do
  jetty_params = Jettywrapper.load_config('test')
  jetty_params[:startup_wait]= 60
  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task["test:seed"].invoke
    Rake::Task['spec'].invoke
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
