require 'test_helper'
require 'rubygems'
require 'sitemap_generator'
require 'rake'

class SessionStoreTest < ActionDispatch::IntegrationTest

  def setup
    @models = FactoryBot.create_list(:model,3, policy:FactoryBot.create(:public_policy))
    @sops = FactoryBot.create_list(:sop,3, policy:FactoryBot.create(:public_policy))
    @projects = Project.all
    @people = Person.all
    @institutions = Institution.all

    sitemap_path = "#{Rails.root}/public/sitemap.xml"
    sitemaps_dir = "#{Rails.root}/public/sitemaps"
    FileUtils.rm(sitemap_path) if File.exist?(sitemap_path)
    FileUtils.rm_rf(sitemaps_dir) if File.exist?(sitemaps_dir)

    SitemapGenerator::Interpreter.run(verbose: false)
  end

  test 'root sitemap' do
    get '/sitemaps/sitemap.xml'
  end

end
