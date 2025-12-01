# Activity Logging and Configuration

# Log activity
[$project, $investigation, $study, $exp_assay, $model_assay, $data_file1, $data_file2, $model, $publication].each do |item|
  ActivityLog.create(action: 'create',
                     culprit: $guest_user,
                     controller_name: item.class.name.underscore.pluralize,
                     activity_loggable: item,
                     data: item.title)
end

# Updating programme
disable_authorization_checks do
  $program.programme_administrators = [$guest_person, $admin_person]
  $program.projects = [$project]
  # $program.funding_codes_as_text = ['123456789'] # TODO cannot set funding codes
  # Discussion links...
  $program.save!
end

# Configuration
Seek::Config.home_description = '<p style="text-align:center;font-size:larger;font-weight:bolder">Welcome to the SEEK Sandbox</p>
<p style="text-align:center;font-size:larger;font-weight:bolder">You can log in with the username: <em>guest</em> and password: <em>guest</em></p>
<p style="text-align:center">For more information about SEEK and to see a video, please visit our <a href="http://www.seek4science.org">Website</a>.</p>'

Seek::Config.solr_enabled = true
Seek::Config.isa_enabled = true
Seek::Config.observation_units_enabled = true
Seek::Config.programmes_enabled = true
Seek::Config.programme_user_creation_enabled = true
Seek::Config.noreply_sender = 'no-reply@fair-dom.org'
Seek::Config.instance_name = 'SEEK SANDBOX'
Seek::Config.application_name = 'FAIRDOM-SEEK'
Seek::Config.exception_notification_enabled = true
Seek::Config.exception_notification_recipients = ['errors@fair-dom.org']
Seek::Config.datacite_url = 'https://mds.test.datacite.org/'
Seek::Config.doi_prefix = '10.5072'
Seek::Config.doi_suffix = 'seek.5'
Seek::Config.tag_threshold = 0 # TODO set to 0 or 1 so the tags created in this example_data seeds will be visiblw on the front page.
puts 'Finish configuration'
puts 'Please visit admin site for further configuration, e.g. site_base_host, pubmed_api_email, bioportal_api_key, email, doi, admin email'
puts 'Admin account: username admin, password adminadmin. You might want to change admin password.'
puts 'Then make sure solr, workers are running'