#Default values required for the automated unit, functional and integration testing to behave as expected.
if Rails.env.test?
  silence_warnings do
    Settings.application_name = 'Sysmo SEEK'
    Settings.application_title = 'The Sysmo SEEK'
    Settings.project_name = 'Sysmo'
    Settings.project_title = 'The Sysmo Consortium'
    Settings.dm_project_name = 'Sysmo-DB'
    Settings.noreply_sender ="no-reply@sysmo-db.org"

    Settings.crossref_api_email = "sowen@cs.man.ac.uk"

    Settings.events_enabled = true
  end
end
