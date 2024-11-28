require 'rubygems'
require 'rails/all'
require 'rake'
require 'json'

namespace :seek do
  namespace :scrapers do
    desc 'Scrape workflows'
    task scrape: :environment do
      Scrapers::Util.scrape
      puts 'Done'
    end
  end
end
