# https://github.com/kjvarga/sitemap_generator#sitemapgenerator

SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps'
SitemapGenerator::Sitemap.compress = false
SitemapGenerator::Sitemap.include_root = false
SitemapGenerator::Sitemap.default_host = URI.parse(Seek::Config.site_base_url)

SitemapGenerator::Sitemap.create do
  types = Seek::Util.searchable_types

  group(filename: :site) do
    add root_path, changefreq: 'daily', priority: 1.0
    types.each do |type|
      add polymorphic_path(type), lastmod: type.maximum(:updated_at), changefreq: 'daily', priority: 0.7
    end
  end

  types.each do |type|
    group(filename: type.table_name) do
      type.authorized_for('view', nil).each do |resource|
        add polymorphic_path(resource), lastmod: resource.updated_at, changefreq: 'weekly', priority: 0.7
      end
    end
  end
end
