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

    sitemaps_dir = "#{Rails.root}/public/sitemaps"
    FileUtils.rm_rf(sitemaps_dir) if File.exist?(sitemaps_dir)

    SitemapGenerator::Interpreter.run(verbose: false)
  end

  test 'root sitemap' do
    get '/sitemap.xml'
    assert_response :success
  end

end
