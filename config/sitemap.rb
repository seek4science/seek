# https://github.com/kjvarga/sitemap_generator#sitemapgenerator
SitemapGenerator::Sitemap.sitemaps_path = "sitemaps"
SitemapGenerator::Sitemap.create_index = "auto"
SitemapGenerator::Sitemap.compress = false
SitemapGenerator::Sitemap.default_host = URI.parse(Seek::Config.site_base_url)

SitemapGenerator::Sitemap.create do
  Seek::Util.searchable_types.each do |type|
    add  polymorphic_path(type), lastmod: type.maximum(:updated_at), changefreq: 'daily', priority: 0.7
  end
end

Seek::Util.searchable_types.each do |type|
  SitemapGenerator::Sitemap.create(filename: type.table_name, include_root: false) do
    type.authorized_for('view', nil).find_all do |obj|
      add polymorphic_path(obj), lastmod: obj.updated_at, changefreq: 'daily', priority: 0.7
    end
  end
end
