#Default values required for the automated unit, functional and integration testing to behave as expected.
if Rails.env.test?
  silence_warnings do
    Settings.defaults[:application_name] = 'Sysmo SEEK'
    Settings.defaults[:application_title] = 'The Sysmo SEEK'
    Settings.defaults[:project_name] = 'Sysmo'
    Settings.defaults[:project_title] = 'The Sysmo Consortium'
    Settings.defaults[:dm_project_name] = 'Sysmo-DB'
    Settings.defaults[:noreply_sender] ="no-reply@sysmo-db.org"

    Settings.defaults[:crossref_api_email] = "sowen@cs.man.ac.uk"

    Settings.defaults[:events_enabled] = true
    Settings.defaults[:solr_enabled] = false
    Settings.defaults[:email_enabled] = false
    Settings.defaults[:exception_notification_enabled] = false
    Settings.defaults[:hide_details_enabled] = false
    Settings.defaults[:activation_required_enabled] = false
    Settings.defaults[:google_analytics_enabled] = false
    Settings.defaults[:header_image_enabled] = false
    Settings.defaults[:copyright_addendum_enabled] = false
  end
end
