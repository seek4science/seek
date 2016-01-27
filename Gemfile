source 'https://rubygems.org'

gem "rails", "3.2.22"
gem "rdoc"

#added by TZ to fix problem with compiling the assets without js env.
gem 'therubyracer', :platforms => :ruby

gem "feedjira","~>1"
gem "google-analytics-rails"
gem 'hpricot',"~>0.8.2"
gem 'libxml-ruby',">=2.6.0",:require=>"libxml"
gem 'uuid',"~>2.3"
gem "RedCloth","4.2.9"
gem 'simple-spreadsheet-extractor',"~>0.15.0"
gem "rmagick","2.15.2"
gem "mysql2"
gem 'rest-client'
gem 'factory_girl', "2.6.4"
gem 'rubyzip', "~> 1.1.4"
gem 'bio'
gem 'sunspot_rails',"~>2.2.0"
gem 'sunspot_solr',"~>2.2.0"
gem 'savon',"1.1.0"
gem "dynamic_form"
gem "prototype-rails"
gem "delayed_job_active_record"
gem "daemons"
gem "cancan"
gem "in_place_editing"
gem "linkeddata"

gem "equivalent-xml"
gem "breadcrumbs_on_rails"
gem 'docsplit'
gem "pothoven-attachment_fu"
gem "exception_notification"
gem "fssm"
gem 'acts-as-taggable-on',"3.0.1"
gem 'acts_as_list'
gem 'acts_as_tree'
gem 'country-select'
gem 'modporter-plugin'
gem "will_paginate", "~> 3.0.4"
gem 'calendar_date_select', :git => 'https://github.com/paneq/calendar_date_select.git'
gem "yaml_db"
gem 'rails_autolink'
gem 'rfc-822'
gem 'nokogiri'
gem 'rdf-virtuoso', ">=0.1.6"
gem 'cocaine'
gem 'colorize','0.7.4'
gem 'lograge'
gem 'psych'
gem 'transaction_isolation'
gem 'validate_url'

#gem for BiVeS and BudHat
gem 'bives'


#Linked to SysMO Git repositories
gem 'gibberish', :git => "https://github.com/SysMO-DB/gibberish.git"
gem 'white_list', :git => "https://github.com/SysMO-DB/white_list.git"
gem 'white_list_formatted_content', :git => "https://github.com/SysMO-DB/white_list_formatted_content.git"
gem 'my_rails_settings', :git => "https://github.com/SysMO-DB/my_rails_settings.git", :require=>"settings"
gem 'piwik_analytics',:git=>"https://github.com/SysMO-DB/piwik-ruby-tracking.git"
gem 'my_savage_beast', :git => "https://github.com/SysMO-DB/my_savage_beast"
gem 'redbox', :git=>"https://github.com/SysMO-DB/redbox"
gem "my_responds_to_parent", :git => "https://github.com/SysMO-DB/my_responds_to_parent.git"
gem 'bioportal',">=2.2"
gem 'acts_as_activity_logged', :git => "https://github.com/SysMO-DB/acts_as_activity_logged.git"
gem 'acts_as_trashable',:git=> "https://github.com/SysMO-DB/acts_as_trashable.git"
gem "app_version", :git => "https://github.com/SysMO-DB/app_version.git"
gem 'doi_query_tool', :git => "https://github.com/SysMO-DB/doi_query_tool.git"
gem 'convert_office',:git=>"https://github.com/SysMO-DB/convert_office.git", :ref=>"753f2567dbd625bc89071e1150404efbb562e130"
gem "fleximage", :git=>"https://github.com/SysMO-DB/fleximage", :ref=>"bb1182f2716a9bf1b5d85e186d8bb7eec436797b"
gem 'search_biomodel', "2.2.1",:git=>"https://github.com/myGrid/search_biomodel.git"
gem 'my_annotations', :git=>"https://github.com/myGrid/annotations.git"

gem 'site_announcements'
gem 'taverna-t2flow'
gem "taverna-player", :git=>"https://github.com/myGrid/taverna-player.git", :branch => 'list-inputs', :ref=>"b36e19c85b7a58d08a73aa418c0f838442c6dfd3"
gem 'jquery-rails', '~> 3'
gem 'jquery-ui-rails', '~>3'
gem "recaptcha"
gem 'metainspector'
gem 'mechanize'
gem 'mimemagic'

gem 'datacite_doi_ify', '~>1.1.0'

gem 'bootstrap-sass', '3.1.1.0'
gem 'sass-rails', '>= 3.2'

gem 'ro-bundle'
gem 'bootstrap-tagsinput-rails'
gem 'bootstrap-typeahead-rails'
gem 'bootstrap-multiselect-rails'
gem 'handlebars_assets'
gem "zenodo-client", :git=>"https://github.com/seek4science/zenodo-client.git"

gem 'unicorn-rails'

group :assets do
  gem 'turbo-sprockets-rails3'
  gem 'yui-compressor'
end

group :production do
  gem 'passenger'
end

group :development do
  gem "pry"
  gem "pry-doc"
  gem "pry-remote"
  gem "request-log-analyzer"
  gem "rubocop",:require=>false
  gem "rubycritic",:require=>false
  gem "guard-rubycritic",:require=>false
  gem 'rails_best_practices'
  #disables the started get, severved assets logs
  gem 'quiet_assets', group: :development
end

group :test do
  gem 'test_after_commit'
  gem "sqlite3"
  gem "ruby-prof"
  gem "webmock"
  gem "minitest","~> 4.0"
  gem 'minitest-reporters'
  gem 'coveralls', require: false
  gem 'rspec-rails'
  gem 'sunspot_matchers'
  gem 'pg'
  gem 'teaspoon'
  gem "teaspoon-mocha"
  gem "magic_lamp"
  gem 'database_cleaner'
  gem 'selenium-webdriver'
end
