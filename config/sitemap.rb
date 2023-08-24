# See the readme at https://github.com/lassebunk/dynamic_sitemaps
base_url = URI.parse(Seek::Config.site_base_url)
host_with_port = base_url.host
if base_url.port != base_url.default_port
  host_with_port += ":#{base_url.port}"
end

protocol base_url.scheme
host host_with_port

# You can have multiple sitemaps – just make sure their names are different.
sitemap :site do
  url root_url, last_mod: Time.now, change_freq: 'daily', priority: 1.0
  for type in Seek::Util.searchable_types do
    url  polymorphic_url(type), last_mod: type.maximum(:updated_at), change_freq: 'daily', priority: 0.7
  end
end

for type in Seek::Util.searchable_types do
  sitemap_for type.authorized_for('view', nil) unless type == SampleType
end
sitemap_for SampleType


# Ping search engines after sitemap generation:
ping_with "#{base_url.scheme}://#{host}/sitemap.xml" if Rails.env.production?
