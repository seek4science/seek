require 'test_helper'
require 'sitemap_generator'

class SitemapTest < ActionDispatch::IntegrationTest
  def setup
    disable_authorization_checks do
      DataFile.destroy_all
      Model.destroy_all
      Sop.destroy_all
    end
    @models = FactoryBot.create_list(:model, 3, policy: FactoryBot.create(:public_policy))
    @private_model = FactoryBot.create(:model, policy: FactoryBot.create(:private_policy))
    @sops = FactoryBot.create_list(:sop, 3, policy: FactoryBot.create(:public_policy))
    @projects = Project.all
    @people = Person.all
    @institutions = Institution.all

    sitemaps_dir = "#{Rails.root}/public/sitemaps"
    FileUtils.rm_rf(sitemaps_dir) if File.exist?(sitemaps_dir)

    with_config_value(:sops_enabled, false) do
      SitemapGenerator::Interpreter.run(verbose: false)
    end
  end

  test 'root sitemap' do
    get '/sitemap.xml'
    assert_response :success
    doc = Nokogiri::XML.parse(response.body)
    doc.remove_namespaces!
    assert_equal 1, doc.xpath('//sitemapindex').count
    assert_equal 1, doc.xpath('//sitemapindex/sitemap/loc[text()="http://localhost:3000/sitemaps/site.xml"]').count
    assert_equal 1, doc.xpath('//sitemapindex/sitemap/loc[text()="http://localhost:3000/sitemaps/models.xml"]').count
    assert_equal 1, doc.xpath('//sitemapindex/sitemap/loc[text()="http://localhost:3000/sitemaps/projects.xml"]').count
    assert_equal 1, doc.xpath('//sitemapindex/sitemap/loc[text()="http://localhost:3000/sitemaps/people.xml"]').count
    assert_equal 1, doc.xpath('//sitemapindex/sitemap/loc[text()="http://localhost:3000/sitemaps/institutions.xml"]').count

    # types without content not shown
    refute DataFile.any?
    assert_equal 0, doc.xpath('//sitemapindex/sitemap/loc[text()="http://localhost:3000/sitemaps/data_files.xml"]').count

    # Disabled not shown
    assert Sop.any?
    assert_equal 0, doc.xpath('//sitemapindex/sitemap/loc[text()="http://localhost:3000/sitemaps/sops.xml"]').count
  end

  test 'resource sitemap' do
    refute DataFile.any?
    assert Sop.any?
    # disabled and empty are not there
    refute File.exist?("#{Rails.root}/public/sitemaps/data_files.xml")
    refute File.exist?("#{Rails.root}/public/sitemaps/sops.xml")

    get '/sitemaps/models.xml'
    assert_response :success

    doc = Nokogiri::XML.parse(response.body)
    doc.remove_namespaces!
    assert_equal 3, doc.xpath('//urlset/url/loc').count
    @models.each do |model|
      assert_equal 1, doc.xpath("//urlset/url/loc[text()=\"http://localhost:3000/models/#{model.id}\"]").count
    end
    assert_equal 0,
                 doc.xpath("//urlset/url/loc[text()=\"http://localhost:3000/models/#{@private_model.id}\"]").count
  end

  test 'site' do
    get '/sitemaps/site.xml'
    assert_response :success

    doc = Nokogiri::XML.parse(response.body)
    doc.remove_namespaces!

    # +1 for root path, and -1 for disabled SOPs
    expected_count = Seek::Util.searchable_types.count

    assert_equal expected_count, doc.xpath('//urlset/url').count
    assert_equal 1, doc.xpath('//urlset/url/loc[text()="http://localhost:3000/"]').count
    assert_equal 1, doc.xpath('//urlset/url/loc[text()="http://localhost:3000/institutions"]').count

    # disabled aren't shown, but types without content are
    assert_equal 1, doc.xpath('//urlset/url/loc[text()="http://localhost:3000/data_files"]').count
    assert_equal 0, doc.xpath('//urlset/url/loc[text()="http://localhost:3000/sops"]').count
  end
end
