require 'rake'


require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

ZIP_URL = "https://github.com/projectblacklight/blacklight-jetty/archive/v4.0.0.zip"
APP_ROOT = File.dirname(__FILE__)

TEST_APP_TEMPLATES = 'spec/test_app_templates'
TEST_APP = 'spec/internal'
require 'jettywrapper'

task :default => :ci

desc "Run specs"
RSpec::Core::RakeTask.new do |t|

end

task :ci => ['test:generate', 'jetty:clean'] do
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

  desc "Clean out the test rails app"
  task :clean do
    puts "Removing sample rails app"
    `rm -rf #{TEST_APP}`
  end

  desc "Create the test rails app"
  task :generate do
    unless File.exists?('spec/internal/Rakefile')
      puts "Generating rails app"
      `rails new #{TEST_APP}`
      puts "Copying gemfile"
      open("#{TEST_APP}/Gemfile", 'a') do |f|
        f.write File.read(TEST_APP_TEMPLATES + "/Gemfile.extra")
        f.write "gem 'blacklight_range_limit', :path => '../../'" 
      end
      puts "Copying generator"
      `cp -r #{TEST_APP_TEMPLATES}/lib/generators #{TEST_APP}/lib`
      within_test_app do
        puts "Bundle install"
        `bundle install`
        puts "running test_app_generator"
        system "rails generate test_app"

        puts "running migrations"
        puts `rake db:migrate db:test:prepare`
      end
    end
    puts "Done generating test app"
  end
end

def within_test_app
  FileUtils.cd(TEST_APP)
  Bundler.with_clean_env do
    yield
  end
  FileUtils.cd(APP_ROOT)
end