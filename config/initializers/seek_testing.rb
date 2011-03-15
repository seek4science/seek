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
    Settings.defaults[:jws_enabled] = true
  end
end
