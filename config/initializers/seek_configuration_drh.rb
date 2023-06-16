SEEK::Application.configure do

  # Branding
  Seek::Config.instance_name = 'SciLifeLab Digital Research Hub'
  Seek::Config.instance_link = 'https://www.scilifelab.se/data/'
  Seek::Config.issue_tracker = 'https://github.com/ScilifelabDataCentre/seek/issues'
  Seek::Config.instance_admins_name = "SciLifeLab Data Centre"
  Seek::Config.instance_admins_link = "https://www.scilifelab.se/data/"
  Seek::Config.header_image_title = "The SciLifeLab Digital Research Hub logo"

  Seek::Config.home_description = '<h3>Welcome to SciLifeLab Digital Research Hub</h3> <strong>CURRENTLY THIS SITE IS FOR TESTING PURPOSES ONLY.</strong><br><strong>INFORMATION STORED IN THIS SITE WILL BE DELETED FREQUENTLY AND WITHOUT WARNING.</strong>'
  Seek::Config.home_description_position = 'middle'

  #Seek::Config.about_instance_link_enabled = true
  #Seek::Config.about_instance_admins_link_enabled = true

  Seek::Config.require_cookie_consent = true
  Seek::Config.privacy_enabled = true
  Seek::Config.terms_enabled = true

  # Enabled/Disabled features - mostly where different from defaults
  Seek::Config.solr_enabled = true
  Seek::Config.filtering_enabled = true
  Seek::Config.programme_user_creation_enabled = true
  Seek::Config.project_single_page_enabled = true
  Seek::Config.project_single_page_advanced_enabled = true

  # Enabled/Disabled resource types
  Seek::Config.programmes_enabled = true
  Seek::Config.file_templates_enabled = true
  Seek::Config.sample_type_template_enabled = true

  # Enabled/Disabled integrations
  Seek::Config.jws_enabled = false

end
