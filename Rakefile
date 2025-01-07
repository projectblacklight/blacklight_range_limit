require 'rake'
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
require 'engine_cart/rake_task'
require 'solr_wrapper'

task :default => :ci

desc "Run specs"
RSpec::Core::RakeTask.new

# rspec hooks up spec task with spec:prepapre dependency. But we need to make sure
# it gets called *within test app* so for jsbundling-rails JS is properly built.
# So we add our custom as a dependency.
task spec: ["test:spec:prepare"]

task ci: ['engine_cart:generate'] do
  SolrWrapper.wrap do |solr|
    solr.with_collection(name: 'blacklight-core', dir: File.join(File.expand_path(File.dirname(__FILE__)), "solr", "conf")) do
      Rake::Task["test:seed"].invoke
      Rake::Task['spec'].invoke
    end
  end
end

desc "check npm and gem versions match before release"
task :guard_version_match do
  gem_version = File.read(__dir__ + "/VERSION").chomp
  npm_version = JSON.parse(File.read(__dir__ + "/package.json"))["version"]

  # 9.0.0.beta1 in gem becomes 9.0.0-beta1 in npm
  gem_version_parts = gem_version.split(".")

  npm_version_required = [
    gem_version_parts.slice(0, 3).join("."),
    gem_version_parts.slice(3, gem_version_parts.length).join(".")
  ].collect {|s| s if s && !s.empty? }.compact.join("-")

  if npm_version != npm_version_required
    raise <<~EOS
      You should not publish without npm version in package.json matching gem version

      gem version: #{gem_version}
      package.json version: #{npm_version}

      expected package.json version: #{npm_version_required}

    EOS
  end
end

# Get our guard to run before `rake release`'s, and warning afterwards
task "release:guard_clean" => :guard_version_match
Rake::Task["guard_version_match"].enhance do
  puts <<~EOS

    ⚠️  Please remember to run `npm publish` the npm package too!  ⚠️

    If you don't have permission, please ask someone who does for help.
    https://www.npmjs.com/package/blacklight-range-limit

  EOS
end


namespace :test do
  namespace :spec do
    desc "call task spec:prepare within test app"
    task :prepare do
      within_test_app do
        system "bin/rake spec:prepare"
      end
    end
  end

  desc "Put sample data into solr"
  task seed: ['engine_cart:generate'] do
    within_test_app do
      ENV['RAILS_ENV'] ||= 'test'
      system "rake blacklight:index:seed"
      system "rake blacklight_range_limit:seed"
    end
  end

  desc "run just solr, useful for local tests"
  task :solr, [:rails_sever_args] do |_t, args|
    unless File.exist? EngineCart.destination
      Rake::Task['engine_cart:generate'].invoke
    end

    SolrWrapper.wrap(port: '8983') do |solr|
      solr.with_collection(name: 'blacklight-core', dir: File.join(File.expand_path(File.dirname(__FILE__)), "solr", "conf")) do
        Rake::Task['test:seed'].invoke
        # sleep forever, make us cntrl-c to get out
        puts "solr is running on port 8983, ctrl-c to exit..."
        system "while true; do sleep 10000; done"
      end
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
