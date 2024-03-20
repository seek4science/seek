require 'test_helper'
require 'sitemap_generator'


class SitemapTest < ActionDispatch::IntegrationTest

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
    doc = Nokogiri::XML.parse(response.body)
    doc.remove_namespaces!
    assert_equal 1, doc.xpath('//sitemapindex').count
    assert_equal 1, doc.xpath('//sitemapindex/sitemap/loc[text()="http://localhost:3000/sitemaps/site.xml"]').count
    assert_equal 1, doc.xpath('//sitemapindex/sitemap/loc[text()="http://localhost:3000/sitemaps/models.xml"]').count
    assert_equal 1, doc.xpath('//sitemapindex/sitemap/loc[text()="http://localhost:3000/sitemaps/sops.xml"]').count
    assert_equal 1, doc.xpath('//sitemapindex/sitemap/loc[text()="http://localhost:3000/sitemaps/projects.xml"]').count
    assert_equal 1, doc.xpath('//sitemapindex/sitemap/loc[text()="http://localhost:3000/sitemaps/people.xml"]').count
    assert_equal 1, doc.xpath('//sitemapindex/sitemap/loc[text()="http://localhost:3000/sitemaps/institutions.xml"]').count
  end

end
