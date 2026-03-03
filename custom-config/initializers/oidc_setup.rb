# Ensure the default OIDC institution exists at application startup.
# Runs after all initializers and models are fully loaded.
Rails.application.config.after_initialize do
  next unless Seek::Config.omniauth_oidc_enabled

  title   = ENV.fetch('OMNIAUTH_OIDC_DEFAULT_INSTITUTION', 'Default Institution')
  country = ENV.fetch('OMNIAUTH_OIDC_DEFAULT_INSTITUTION_COUNTRY', 'GB')
  city    = ENV.fetch('OMNIAUTH_OIDC_DEFAULT_INSTITUTION_CITY', '')
  web     = ENV.fetch('OMNIAUTH_OIDC_DEFAULT_INSTITUTION_WEB', '')

  begin
    institution = Institution.find_or_create_by(title: title) do |inst|
      inst.country  = country
      inst.city     = city
      inst.web_page = web.presence
      Rails.logger.info "OIDC Setup: Creating default institution '#{title}' (#{country})"
    end
    Rails.logger.info "OIDC Setup: Default institution '#{institution.title}' ready (id=#{institution.id})"
  rescue => e
    Rails.logger.error "OIDC Setup: Could not create default institution – #{e.message}"
  end
end
