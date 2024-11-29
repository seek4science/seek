require 'rubygems'
require 'rails/all'
require 'rake'
require 'json'

namespace :seek do
  namespace :scrape do
    desc 'Scrape IWC workflows'
    task iwc: :environment do
      project = Scrapers::Util.bot_project(title: 'iwc')
      person = Scrapers::Util.bot_account
      scraper = Scrapers::IwcScraper.new('iwc-workflows', project, person, main_branch: 'main')

      scraper.scrape
    end

    desc 'Scrape nf-core workflows'
    task nfcore: :environment do
      project = Scrapers::Util.bot_project(title: 'nf-core')
      person = Scrapers::Util.bot_account
      scraper = Scrapers::NfcoreScraper.new('nf-core', project, person)

      scraper.scrape
    end
  end
end
