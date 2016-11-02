# https://github.com/activerecord-hackery/ransack/wiki/Configuration
Ransack.configure do |config|
  # Change default search parameter key name.
  # Default key name is :q
  config.search_key = :query
end

# prevent conflict of search method in gem sunspot_solr
# https://github.com/activerecord-hackery/ransack#ransack-search-method
Ransack::Adapters::ActiveRecord::Base.class_eval('remove_method :search')
