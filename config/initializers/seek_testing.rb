  #Default values required for the automated unit, functional and integration testing to behave as expected.
if Rails.env.test?
  silence_warnings do
    Settings.defaults[:application_title] = 'The Sysmo SEEK'
    Settings.defaults[:project_name] = 'Sysmo'
    Settings.defaults[:project_title] = 'The Sysmo Consortium'

    Settings.defaults[:noreply_sender] ="no-reply@sysmo-db.org"

    Settings.defaults[:crossref_api_email] = "sowen@cs.man.ac.uk"

    Settings.defaults[:jws_enabled] = true
    Settings.defaults[:events_enabled] = true

    Settings.defaults[:email_enabled] = true
    Settings.defaults[:publish_button_enabled] = true
    Settings.defaults[:auth_lookup_enabled] = false
  end
end
