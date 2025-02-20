source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails', '7.2.2.1'
gem 'rdoc'

#database adaptors
gem 'mysql2'
gem 'pg'
gem 'sqlite3'

gem 'feedjira'
gem 'google-analytics-rails'
gem 'libxml-ruby', require: 'libxml'
gem 'uuid'
gem 'RedCloth'
gem 'simple-spreadsheet-extractor'
gem 'open4'
gem 'sample-template-generator'
gem 'rmagick'
gem 'rest-client'
gem 'factory_bot'
gem 'bio'
gem 'sunspot_rails'
gem 'progress_bar'
gem 'savon'
gem 'delayed_job_active_record'
gem 'daemons'
gem 'linkeddata'
gem 'indefinite_article'

gem 'openseek-api'
# for fancy content escaping in openbis integration
gem 'loofah'
gem 'jbuilder'
gem 'jbuilder-json_api'
gem 'active_model_serializers'
gem 'rubyzip'

gem 'equivalent-xml'
gem 'docsplit', git: 'https://github.com/tuttiq/docsplit.git', ref: '6127e3912b8db94ed84dca6be5622d3d5ec0d879' # FIXME: Change back to "official" docsplit if this PR is ever merged: https://github.com/documentcloud/docsplit/pull/159
gem 'exception_notification'
gem 'fssm'
gem 'acts-as-taggable-on'
gem 'acts_as_list'
gem 'acts_as_tree'
gem 'country_select'
gem 'will_paginate'
gem 'yaml_db'
gem 'rails_autolink'
gem 'rfc-822'
gem 'nokogiri', '~> 1.16'
gem 'api_smith', git: 'https://github.com/youroute/api_smith.git', ref: '1fb428cebc17b9afab25ac9f809bde87b0ec315b' #necessary for newer hashie dependency, original api_smith is no longer active
gem 'rdf-virtuoso'
gem 'terrapin'
gem 'lograge'
gem 'psych'
gem 'validate_url'
gem "attr_encrypted"
gem 'libreconv'

# gem for BiVeS and BudHat
gem 'bives'

# Linked to SysMO Git repositories
gem 'my_responds_to_parent', git: 'https://github.com/SysMO-DB/my_responds_to_parent.git'
gem 'bioportal', git: 'https://github.com/SysMO-DB/bioportal.git'
gem 'doi_query_tool', git: 'https://github.com/seek4science/DOI-query-tool.git'
gem 'fleximage', git: 'https://github.com/SysMO-DB/fleximage.git'

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'recaptcha'
gem 'metainspector'
gem 'mechanize'
gem 'mimemagic'
gem 'auto_strip_attributes'
gem 'coffee-rails'
gem 'bootstrap-sass'
gem 'sass-rails'
gem 'sprockets-rails'

gem 'ro-bundle'
gem 'handlebars_assets'
gem 'zenodo-client', git: 'https://github.com/seek4science/zenodo-client.git'

gem 'unicorn-rails'
gem 'seedbank'

gem 'rspec-rails'

gem 'citeproc-ruby'
gem 'csl-styles'
gem 'bibtex-ruby'

gem 'omniauth'
gem 'gitlab_omniauth-ldap'
gem 'omniauth_openid_connect'
gem 'openid_connect'
gem 'omniauth-rails_csrf_protection'
gem 'omniauth-github'

gem 'terser'


# Rails 4 upgrade
gem 'activerecord-session_store'
gem 'rails-observers'
gem 'responders'

gem 'rack-attack'

gem 'private_address_check'

# Rails 5 upgrade
gem 'rails-html-sanitizer'

gem 'bootsnap', require: false

gem 'activerecord-import'

gem "puma"

gem "doorkeeper"

gem 'request_store'

gem 'bundler'

gem 'ro-crate'

gem 'rugged'
gem 'i18n-js'
gem 'whenever', require: false
gem 'dotenv-rails'
gem 'commonmarker'

gem 'rack-cors', require: 'rack/cors'

gem 'addressable'

gem 'json-schema'

gem 'cff'

gem 'remotipart'

gem 'rails-static-router'

gem 'caxlsx'
gem 'caxlsx_rails'

gem 'net-ftp'

gem 'licensee'

gem "sitemap_generator"

# removed from Standard in Ruby 3.4
gem 'observer'
gem 'abbrev'
gem 'csv'
gem 'nkf'
gem 'mutex_m'

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

  gem 'web-console'
  gem 'rack-mini-profiler'
  gem "flamegraph"
  gem "stackprof"
  gem 'listen'
  gem 'ruby-prof'
end

group :test do
  gem 'test-prof'
  gem 'rails-perftest'
  gem 'minitest'
  gem 'minitest-reporters'
  gem 'sunspot_matchers'
  gem 'database_cleaner'
  gem 'vcr'
  gem 'rails-controller-testing'
  gem 'simplecov'
  gem 'whenever-test'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

group :test, :development do
  gem 'magic_lamp'
  gem 'webmock'
  gem 'teaspoon'
  gem 'teaspoon-mocha'
end
