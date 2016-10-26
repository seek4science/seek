# https://github.com/activerecord-hackery/ransack/wiki/Configuration
Ransack.configure do |config|
  # Change default search parameter key name.
  # Default key name is :q
  config.search_key = :query
end