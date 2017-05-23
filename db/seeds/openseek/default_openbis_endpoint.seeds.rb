
disable_authorization_checks do
  endpoint = OpenbisEndpoint.find_or_initialize_by(web_endpoint:'https://openbis/openbis/')
  endpoint.update_attributes(
      as_endpoint: 'https://openbis/openbis/openbis',
      dss_endpoint: 'https://openbis/openbis/datastore_server',
      username: ENV["OPENBIS_USERNAME"],
      password: ENV["OPENBIS_PASSWORD"],
      space_perm_id: 'DEFAULT',
      project_id: Project.first.id
  )
end

Seek::Config.openbis_enabled=true