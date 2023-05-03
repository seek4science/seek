source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails', '~> 6.1.7'
gem 'rdoc'

# database adaptors
gem 'mysql2'
gem 'pg'
gem 'sqlite3', '~> 1.4'

gem 'bio', '~> 1.5.1'
gem 'daemons', '1.1.9'
gem 'delayed_job_active_record'
gem 'factory_girl', '2.6.4'
gem 'feedjira', '~>1'
gem 'google-analytics-rails'
gem 'hpricot', '~>0.8.2'
gem 'indefinite_article'
gem 'libxml-ruby', '~>2.9.0', require: 'libxml'
gem 'linkeddata', '~> 3.2.0'
gem 'open4'
gem 'progress_bar'
gem 'RedCloth', '>=4.3.0'
gem 'rest-client', '~>2.0'
gem 'rmagick', '2.15.2'
gem 'sample-template-generator', '~>0.5'
gem 'savon', '1.1.0'
gem 'simple-spreadsheet-extractor', '~> 0.17.0'
gem 'sunspot_rails'
gem 'uuid', '~>2.3'

gem 'openseek-api'
# for fancy content escaping in openbis integration
gem 'active_model_serializers', '~> 0.10.13'
gem 'jbuilder', '~> 2.7'
gem 'jbuilder-json_api'
gem 'loofah'
gem 'rubyzip'

gem 'acts_as_list'
gem 'acts-as-taggable-on'
gem 'acts_as_tree'
gem 'country_select'
gem 'docsplit'
gem 'equivalent-xml'
gem 'exception_notification'
gem 'fssm'
gem 'nokogiri', '~> 1.13.10'
gem 'pothoven-attachment_fu'
gem 'rails_autolink'
gem 'rfc-822'
gem 'will_paginate', '~> 3.1'
gem 'yaml_db'
# necessary for newer hashie dependency, original api_smith is no longer active
gem 'api_smith', git: 'https://github.com/youroute/api_smith.git', ref: '1fb428cebc17b9afab25ac9f809bde87b0ec315b'
gem 'attr_encrypted', '~> 3.0.0'
gem 'libreconv'
gem 'lograge'
gem 'psych'
gem 'rdf-virtuoso', '>= 0.2.0'
gem 'stringio', '0.1.0' # locked to the default version for ruby 2.7
gem 'terrapin'
gem 'validate_url'

# gem for BiVeS and BudHat
gem 'bives', '~> 2.0'

# Linked to SysMO Git repositories
gem 'bioportal', '>=3.0', git: 'https://github.com/SysMO-DB/bioportal.git'
gem 'doi_query_tool', git: 'https://github.com/seek4science/DOI-query-tool.git'
gem 'fleximage', git: 'https://github.com/SysMO-DB/fleximage.git', ref: 'bb1182f2716a9bf1b5d85e186d8bb7eec436797b'
gem 'my_responds_to_parent', git: 'https://github.com/SysMO-DB/my_responds_to_parent.git'

gem 'auto_strip_attributes'
gem 'bootstrap-sass', '>=3.4.1'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails', '~> 4.2.2'
gem 'jquery-ui-rails'
gem 'mechanize'
gem 'metainspector'
gem 'mimemagic', '~> 0.3.7'
gem 'recaptcha', '~> 4.1.0'
gem 'sass-rails', '>= 6'
gem 'sprockets-rails'

gem 'handlebars_assets'
gem 'ro-bundle', '~> 0.3.0'
gem 'zenodo-client', git: 'https://github.com/seek4science/zenodo-client.git'

gem 'seedbank'
gem 'unicorn-rails'

gem 'rspec-rails', '~> 5.1'

gem 'bibtex-ruby', '~> 5.1.0'
gem 'citeproc-ruby', '~> 2.0.0'
gem 'csl-styles', '~> 2.0.0'

gem 'gitlab_omniauth-ldap', '~> 2.2.0'
gem 'omniauth', '~> 2.1.0'
gem 'omniauth-github'
gem 'omniauth_openid_connect'
gem 'omniauth-rails_csrf_protection'
gem 'openid_connect', '1.3.0'

gem 'ransack'

gem 'terser', '~> 1.1', '>= 1.1.1'

# Rails 4 upgrade
gem 'activerecord-session_store'
gem 'rails-observers'
gem 'responders'

gem 'rack-attack', '~> 6.6.0'

gem 'private_address_check'

# Rails 5 upgrade
gem 'rails-html-sanitizer'

gem 'bootsnap', '>= 1.4.4', require: false

gem 'activerecord-import'

gem 'puma', '~> 5.6'

gem 'doorkeeper', '>= 5.2.5'

gem 'request_store'

gem 'bundler', '>= 1.8.4'

gem 'ro-crate', '~> 0.5.1'

gem 'commonmarker'
gem 'dotenv-rails', '~> 2.7.6'
gem 'i18n-js'
gem 'rugged'
gem 'whenever', '~> 1.0.0', require: false

gem 'rack-cors', require: 'rack/cors'

gem 'addressable'

gem 'json-schema'

gem 'cff', '~> 0.9.0'

gem 'remotipart', '~> 1.4.4' # Allows file upload in AJAX forms

gem 'rails-static-router'

gem 'caxlsx', '>= 3.0' # Write content to an xlsx file
gem 'caxlsx_rails', '~> 0.6.2'

# to avoid warnings after rails 6.1.7.2 update - see https://github.com/ruby/net-imap/issues/16
gem "net-http"
gem "net-ftp"
gem "uri", "0.10.0.2"

group :production do
  gem 'passenger'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'gem-licenses'
  gem 'pry'
  gem 'pry-doc'
  gem 'pry-remote'
  gem 'rails_best_practices'
  gem 'request-log-analyzer'
  gem 'rubocop', require: false

  gem 'listen', '~> 3.3'
  gem 'rack-mini-profiler', '~> 2.0'
  gem 'web-console', '>= 4.1.0'
end

group :test do
  gem 'database_cleaner', '~> 1.7.0'
  gem 'minitest', '~> 5.14'
  gem 'minitest-reporters'
  gem 'rails-controller-testing'
  gem 'rails-perftest'
  gem 'ruby-prof'
  gem 'simplecov'
  gem 'sunspot_matchers'
  gem 'test-prof'
  gem 'vcr', '~> 2.9'
  gem 'whenever-test'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

group :test, :development do
  gem 'magic_lamp'
  gem 'teaspoon'
  gem 'teaspoon-mocha'
  gem 'webmock'
end
