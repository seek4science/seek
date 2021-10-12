require 'rubygems'
require 'rails/all'
require 'rake'

namespace :seek do
  namespace :scrape do
    desc 'Scrape IWC workflows'
    task iwc: :environment do
      project = Scrapers::Util.bot_project(title: 'iwc')
      person = Scrapers::Util.bot_account
      scraper = Scrapers::IwcScraper.new('iwc-workflows', project, person, main_branch: 'main')

      scraper.scrape
    end
  end
end
