require 'rails/generators'

namespace :blacklight_range_limit do
  desc 'Add in additional Solr docs'
  task seed: :environment do
    solr = CatalogController.new.repository.connection
    docs = Dir['spec/fixtures/solr_documents/*.yml'].map { |f| YAML.load File.read(f) }.flatten
    solr.add docs
    solr.commit
  end
end
