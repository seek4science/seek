Rails.configuration.after_initialize do
  SEEK::Application.configure do
    Seek::Config.default :solr_enabled, true
  end
end

