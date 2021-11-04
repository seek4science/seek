source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails', '~> 5.2.4.0'
gem 'rdoc'

#database adaptors
gem 'mysql2'
gem 'pg'
gem 'sqlite3'

gem 'feedjira', '~>1'
gem 'google-analytics-rails'
gem 'hpricot', '~>0.8.2'
gem 'libxml-ruby', '~>2.9.0', require: 'libxml'
gem 'uuid', '~>2.3'
gem 'RedCloth', '>=4.3.0'
gem 'simple-spreadsheet-extractor', '~>0.16.0'
gem 'sample-template-generator', '~>0.5'
gem 'rmagick', '2.15.2'
gem 'rest-client', '~>2.0'
gem 'factory_girl', '2.6.4'
gem 'bio', '~> 1.5.1'
gem 'sunspot_rails'
gem 'progress_bar'
gem 'savon', '1.1.0'
gem 'dynamic_form'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'linkeddata'
gem 'rdf'

gem 'openseek-api'
# for fancy content escaping in openbis integration
gem 'loofah'
gem 'jbuilder'
gem 'jbuilder-json_api'
gem 'active_model_serializers', '~> 0.10.2'
gem 'json-schema'
gem 'json-diff'
gem 'rubyzip'

gem 'equivalent-xml'
gem 'docsplit'
gem 'pothoven-attachment_fu'
gem 'exception_notification'
gem 'fssm'
gem 'acts-as-taggable-on'
gem 'acts_as_list'
gem 'acts_as_tree'
gem 'country_select'
gem 'will_paginate', '~> 3.1'
gem 'yaml_db'
gem 'rails_autolink'
gem 'rfc-822'
gem 'nokogiri', '~> 1.12.5'
gem 'rdf-virtuoso', '>= 0.2.0'
gem 'terrapin'
gem 'lograge'
gem 'psych'
gem 'validate_url'
gem "attr_encrypted", "~> 3.0.0"

# gem for BiVeS and BudHat
gem 'bives', "~> 2.0"

# Linked to SysMO Git repositories
gem 'my_responds_to_parent', git: 'https://github.com/SysMO-DB/my_responds_to_parent.git'
gem 'bioportal', '>=3.0', git: 'https://github.com/SysMO-DB/bioportal.git'
gem 'doi_query_tool', git: 'https://github.com/seek4science/DOI-query-tool.git'
gem 'convert_office', git: 'https://github.com/SysMO-DB/convert_office.git', ref: '753f2567dbd625bc89071e1150404efbb562e130'
gem 'fleximage', git: 'https://github.com/SysMO-DB/fleximage.git', ref: 'bb1182f2716a9bf1b5d85e186d8bb7eec436797b'

gem 'jquery-rails', '~> 4.2.2'
gem 'jquery-ui-rails'
gem 'recaptcha', '~> 4.1.0'
gem 'metainspector'
gem 'mechanize'
gem 'mimemagic','~> 0.3.7'
gem 'auto_strip_attributes'
gem 'coffee-rails', '~> 4.2'
gem 'bootstrap-sass', '>=3.4.1'
gem 'sass-rails', '~> 5.0'
gem 'sprockets-rails'

gem 'ro-bundle', '~> 0.2.5'
gem 'handlebars_assets'
gem 'zenodo-client', git: 'https://github.com/seek4science/zenodo-client.git'

gem 'unicorn-rails'
gem 'seedbank'

gem 'rspec-rails','~> 3.6'

gem 'citeproc-ruby', '~> 1.1.4'
gem 'citeproc', '~> 1.0.4'
gem 'csl-styles', '~> 1.0.1.11'
gem 'bibtex-ruby', '~> 5.1.0'

gem 'omniauth', '~> 1.3.1'
gem 'omniauth-ldap', '~> 1.0.5'
gem 'omniauth_openid_connect'
gem 'omniauth-rails_csrf_protection', '~> 0.1'
gem 'omniauth-github', '~> 1.2.0'

gem 'ransack'

gem 'uglifier'

# Rails 4 upgrade
gem 'activerecord-session_store'
gem 'rails-observers'
gem 'responders'

gem 'rack-attack', '~> 5.0.1'

gem 'private_address_check'

# Rails 5 upgrade
gem 'rails-html-sanitizer'

# Rails 5.2 upgrade
gem 'bootsnap', '>= 1.1.0', require: false

gem 'activerecord-import'

gem "puma", "~>4.3"

gem "doorkeeper", ">= 5.2.5"

gem 'request_store'

gem 'bundler', '>= 1.8.4'

gem 'ro-crate', '~> 0.4.14'

gem 'git'
gem 'i18n-js'
gem 'whenever', '~> 1.0.0', require: false
gem 'dotenv-rails', '~> 2.7.6'
gem 'commonmarker'

group :production do
  gem 'passenger'
end

group :development do
  gem 'pry'
  gem 'pry-doc'
  gem 'pry-remote'
  gem 'request-log-analyzer'
  gem 'rubocop', require: false
  gem 'rails_best_practices'
  gem 'gem-licenses'
  gem "better_errors"
  gem "binding_of_caller"
end

group :test do
  gem 'ruby-prof'
  gem 'test-prof'
  gem 'rails-perftest'
  gem 'minitest', '~> 5.14'
  gem 'minitest-reporters'
  gem 'sunspot_matchers'
  gem 'database_cleaner', '~> 1.7.0'
  gem 'vcr', '~> 2.9'
  gem 'rails-controller-testing'
  gem 'simplecov'
  gem 'whenever-test'
end

group :test, :development do
  gem 'magic_lamp'
  gem 'webmock'
  gem 'teaspoon'
  gem 'teaspoon-mocha'
end
