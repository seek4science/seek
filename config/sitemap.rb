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

  url investigations_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
  url studies_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
  url assays_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
  url data_files_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
  url models_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
  url sops_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
  url publications_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
  url documents_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
  url collections_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
  url presentations_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
  url events_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
  url samples_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
  url templates_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
  url strains_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
  url workflows_url, last_mod: Time.now, change_freq: 'daily', priority: 0.7
end

sitemap_for Investigation.joins(:policy).where(policies: {access_type: Policy::VISIBLE}) if Seek::Config.investigations_enabled
sitemap_for Study.joins(:policy).where(policies: {access_type: Policy::VISIBLE}) if Seek::Config.studies_enabled
sitemap_for Assay.joins(:policy).where(policies: {access_type: Policy::VISIBLE}) if Seek::Config.assays_enabled
sitemap_for DataFile.joins(:policy).where(policies: {access_type: Policy::VISIBLE}) if Seek::Config.data_files_enabled
sitemap_for Model.joins(:policy).where(policies: {access_type: Policy::VISIBLE}) if Seek::Config.models_enabled
sitemap_for Sop.joins(:policy).where(policies: {access_type: Policy::VISIBLE}) if Seek::Config.sops_enabled
sitemap_for Publication.joins(:policy).where(policies: {access_type: Policy::VISIBLE}) if Seek::Config.publications_enabled
sitemap_for Document.joins(:policy).where(policies: {access_type: Policy::VISIBLE}) if Seek::Config.documents_enabled
sitemap_for Collection.joins(:policy).where(policies: {access_type: Policy::VISIBLE}) if Seek::Config.collections_enabled
sitemap_for Presentation.joins(:policy).where(policies: {access_type: Policy::VISIBLE}) if Seek::Config.presentations_enabled
sitemap_for Event.joins(:policy).where(policies: {access_type: Policy::VISIBLE}) if Seek::Config.events_enabled
sitemap_for Sample.joins(:policy).where(policies: {access_type: Policy::VISIBLE}) if Seek::Config.samples_enabled
sitemap_for Template.joins(:policy).where(policies: {access_type: Policy::VISIBLE}) if Seek::Config.file_templates_enabled
sitemap_for Strain.joins(:policy).where(policies: {access_type: Policy::VISIBLE})
sitemap_for Workflow.joins(:policy).where(policies: {access_type: Policy::VISIBLE}) if Seek::Config.workflows_enabled


# Ping search engines after sitemap generation:
ping_with "#{base_url.scheme}://#{host}/sitemap.xml" if Rails.env.production?
