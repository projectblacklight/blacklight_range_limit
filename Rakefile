require 'rake'


require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'


TEST_APP_TEMPLATES = 'spec/test_app_templates'
TEST_APP = 'spec/internal'
require 'engine_cart/rake_task'

ZIP_URL = "https://github.com/projectblacklight/blacklight-jetty/archive/v4.0.0.zip"
APP_ROOT = File.dirname(__FILE__)

require 'jettywrapper'

task :default => :ci

desc "Run specs"
RSpec::Core::RakeTask.new do |t|

end

task :ci => ['engine_cart:generate', 'jetty:clean'] do
  ENV['environment'] = "test"
  jetty_params = Jettywrapper.load_config
  jetty_params[:startup_wait]= 60
  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task["test:seed"].invoke
    Rake::Task['spec'].invoke
  end
  raise "test failures: #{error}" if error
end

namespace :test do

  desc "Put sample data into solr"
  task :seed do
    docs = File.join(APP_ROOT, 'solr', 'sample_solr_documents.yml')
    within_test_app do
      system "RAILS_ENV=test rake blacklight_test_app:seed DOC_PATH=#{docs}"
    end
  end

end