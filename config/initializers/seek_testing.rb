#Default values required for the automated unit, functional and integration testing to behave as expected.
if Rails.env.test?
  silence_warnings do
    APPLICATION_NAME       = 'Sysmo SEEK'
    APPLICATION_TITLE      = 'The Sysmo SEEK'
    PROJECT_NAME           = 'Sysmo'
    PROJECT_TITLE          = 'The Sysmo Consortium'
    DM_PROJECT_NAME        = 'Sysmo-DB'
    NOREPLY_SENDER         ="no-reply@sysmo-db.org"

    CROSSREF_API_EMAIL     = "sowen@cs.man.ac.uk"

    PAGINATION_CONFIG_FILE = "config/paginate.yml"

    EVENTS_ENABLED         = true
  end
end