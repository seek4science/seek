source 'https://rubygems.org'

gem 'rails', '~> 4.2.11'
gem 'rdoc'

#database adaptors
gem 'mysql2', '0.4.10'
gem 'pg'
gem 'sqlite3'

gem 'feedjira', '~>1'
gem 'google-analytics-rails'
gem 'hpricot', '~>0.8.2'
gem 'libxml-ruby', '2.8.0', require: 'libxml'
gem 'uuid', '~>2.3'
gem 'RedCloth', '4.2.9'
gem 'simple-spreadsheet-extractor', '~>0.16.0'
gem 'sample-template-generator', '~>0.5'
gem 'rmagick', '2.15.2'
gem 'rest-client', '~>2.0'
gem 'factory_girl', '2.6.4'
gem 'bio', '~> 1.5.1'
gem 'sunspot_rails', '~>2.2.0'
gem 'sunspot_solr', '~>2.2.0'
gem 'progress_bar'
gem 'savon', '1.1.0'
gem 'dynamic_form'
gem 'prototype-rails', git: 'https://github.com/rails/prototype-rails', branch: '4.2'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'linkeddata'

gem 'openseek-api'
# for fancy content escaping in openbis integration
gem 'loofah'

gem 'jbuilder', '~> 2.0'
gem 'jbuilder-json_api'
gem 'active_model_serializers', '~> 0.10.2'
gem 'json-schema'
gem 'json-diff'
gem 'rubyzip', '~> 1.2.2'

gem 'equivalent-xml'
gem 'breadcrumbs_on_rails'
gem 'docsplit'
gem 'pothoven-attachment_fu'
gem 'exception_notification'
gem 'fssm'
gem 'acts-as-taggable-on', '3.0.1'
gem 'acts_as_list'
gem 'acts_as_tree'
gem 'country_select'
gem 'will_paginate', '~> 3.1'
gem 'yaml_db'
gem 'rails_autolink'
gem 'rfc-822'
gem 'nokogiri', '~> 1.8.1'
gem 'rdf-virtuoso', '>=0.1.6'
gem 'terrapin'
gem 'colorize', '0.7.4'
gem 'lograge'
gem 'psych'
gem 'validate_url'
gem "attr_encrypted", "~> 3.0.0"
gem 'app_version'

# gem for BiVeS and BudHat
gem 'bives'

# Linked to SysMO Git repositories
gem 'gibberish', git: 'https://github.com/SysMO-DB/gibberish.git'
gem 'white_list', git: 'https://github.com/SysMO-DB/white_list.git'
gem 'white_list_formatted_content', git: 'https://github.com/SysMO-DB/white_list_formatted_content.git'
gem 'my_responds_to_parent', git: 'https://github.com/SysMO-DB/my_responds_to_parent.git'
gem 'bioportal', '>=3.0', git: 'https://github.com/SysMO-DB/bioportal.git'
gem 'acts_as_activity_logged', git: 'https://github.com/SysMO-DB/acts_as_activity_logged.git'
gem 'doi_query_tool', git: 'https://github.com/seek4science/DOI-query-tool.git'
gem 'convert_office', git: 'https://github.com/SysMO-DB/convert_office.git', ref: '753f2567dbd625bc89071e1150404efbb562e130'
gem 'fleximage', git: 'https://github.com/SysMO-DB/fleximage.git', ref: 'bb1182f2716a9bf1b5d85e186d8bb7eec436797b'
gem 'search_biomodel', '2.2.1', git: 'https://github.com/myGrid/search_biomodel.git'
gem 'my_annotations', git: 'https://github.com/myGrid/annotations.git', branch: 'rails4.2'


gem 'jquery-rails', '~> 3'
gem 'jquery-ui-rails', '~>3'
gem 'recaptcha', '~> 4.1.0'
gem 'metainspector'
gem 'mechanize'
gem 'mimemagic'
gem 'auto_strip_attributes'

gem 'bootstrap-sass'
gem 'sass-rails'
gem 'sprockets-rails', '~> 3.2'

gem 'ro-bundle'
gem 'handlebars_assets'
gem 'zenodo-client', git: 'https://github.com/seek4science/zenodo-client.git'

gem 'unicorn-rails'
gem 'seedbank'

gem 'rspec-rails'

gem 'citeproc-ruby', '~> 1.1.4'
gem 'citeproc', '~> 1.0.4'
gem 'csl-styles', '~> 1.0.1.7'
gem 'bibtex-ruby', '~> 4.4.2'

gem 'omniauth', '~> 1.3.1'
gem 'omniauth-ldap', '~> 1.0.5'

gem 'ransack', '~> 1.8.2'

gem 'uglifier'

gem 'coffee-rails', '~> 4.1.0'

# Rails 4 upgrade
gem 'activerecord-session_store'
gem 'rails-observers'
gem 'responders', '~> 2.0'

gem 'rack-attack', '~> 5.0.1'

gem 'private_address_check'

# javascript assets from https://rails-assets.org
gem 'bundler', '>= 1.8.4'
source 'https://rails-assets.org' do
  gem 'rails-assets-bootstrap-multiselect', '~> 0.9.13'
  gem 'rails-assets-bootstrap-tagsinput', '~> 0.8.0'
  gem 'rails-assets-typeahead.js', '~> 0.10.5'
  gem 'rails-assets-clipboard', '~> 1.5.12'
  gem 'rails-assets-vue', '~> 2.1.8'
  gem 'rails-assets-eonasdan-bootstrap-datetimepicker', '~> 4.17.42'
  gem 'rails-assets-x-editable', '~> 1.5.1'
  gem 'rails-assets-chartjs', '~> 2.7.2'
end

group :production do
  gem 'passenger'
  gem 'puma'
  gem 'system'
end

group :development do
  gem 'pry'
  gem 'pry-doc'
  gem 'pry-remote'
  gem 'request-log-analyzer'
  gem 'rubocop', require: false
  gem 'rubycritic', require: false
  gem 'guard-rubycritic', require: false
  gem 'rails_best_practices'
  gem 'quiet_assets'
  #gem 'ruby-debug-ide', '>= 0.6.1.beta2', require: false
  #gem 'debase', '>= 0.2.2.beta8', require: false
end

group :test do
  gem 'test_after_commit'
  gem 'ruby-prof', '>= 0.16.0'
  gem 'test-prof'
  gem 'rails-perftest'
  gem 'minitest','5.10.3'
  gem 'minitest-reporters'
  gem 'sunspot_matchers'
  gem 'database_cleaner'
  gem 'vcr', '~> 2.9'
end

group :test, :development do
  gem 'magic_lamp'
  gem 'webmock'
  gem 'teaspoon'
  gem 'teaspoon-mocha'
end
