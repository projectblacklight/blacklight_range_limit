require 'rails/generators'

namespace :blacklight_range_limit do
  desc 'Add in additional Solr docs'
  task seed: :environment do
    docs = Dir['spec/fixtures/solr_documents/*.yml'].map { |f| YAML.load File.read(f) }.flatten
    Blacklight.solr.add docs
    Blacklight.solr.commit
  end
end
