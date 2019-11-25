#Default values required for the automated unit, functional and integration testing to behave as expected.
SEEK::Application.configure do
  if Rails.env.test?
    silence_warnings do
      Settings.defaults[:is_virtualliver] = false
      Settings.defaults[:project_hierarchy_enabled] = true
      Settings.defaults[:project_name] = 'Sysmo'

      Settings.defaults[:noreply_sender] ="no-reply@sysmo-db.org"
      Settings.defaults[:support_email_address] = 'support@seek.org'

      Settings.defaults[:crossref_api_email] = "sowen@cs.man.ac.uk"

      Settings.defaults[:jws_enabled] = true
      Settings.defaults[:events_enabled] = true
      Settings.defaults[:jws_online_root] = "http://jws.sysmo-db.org"
      Settings.defaults[:internal_help_enabled] = false
      Settings.defaults[:external_help_url] = "http://seek4science.github.io/seek/help"
      Settings.defaults[:workflows_enabled] = true

      Settings.defaults[:email_enabled] = true

      Settings.defaults[:publish_button_enabled] = true
      Settings.defaults[:auth_lookup_enabled] = false
      Settings.defaults[:project_browser_enabled] = true
      Settings.defaults[:experimental_features_enabled] = true
      Settings.defaults[:filestore_path] = "tmp/testing-filestore"
      Settings.defaults[:tagging_enabled] = true
      Settings.defaults[:authorization_checks_enabled] = true
      Settings.defaults[:magic_guest_enabled] = false
      Settings.defaults[:modelling_analysis_enabled] = true
      Settings.defaults[:assays_enabled] = true
      Settings.defaults[:models_enabled] = true
      Settings.defaults[:show_as_external_link_enabled] = false
      Settings.defaults[:biosamples_enabled] = true
      Settings.defaults[:publications_enabled] = true
      Settings.defaults[:factors_studied_enabled] = true
      Settings.defaults[:experimental_conditions_enabled] = true
      Settings.defaults[:programmes_enabled] = true
      Settings.defaults[:programme_user_creation_enabled] = true
      Settings.defaults[:project_hierarchy_enabled] = true
      Settings.defaults[:tabs_lazy_load_enabled] = false

      Settings.defaults[:project_link] = 'http://www.sysmo.net'
      Settings.defaults[:application_name] = 'Sysmo SEEK'
      Settings.defaults[:dm_project_name] = "SysMO-DB"
      Settings.defaults[:dm_project_link] = "http://www.sysmo-db.org"
      Settings.defaults[:project_type] = 'Consortium'
      Settings.defaults[:header_image_enabled] = true
      Settings.defaults[:header_image_title] =  "SysMO-DB"
      Settings.defaults[:header_image_link] = "http://www.sysmo-db.org"
      Settings.defaults[:bioportal_api_key]="fish"

      Settings.defaults[:technology_type_ontology_file] = "file:#{Rails.root}/test/fixtures/files/JERM-test.rdf"
      Settings.defaults[:modelling_analysis_type_ontology_file] = "file:#{Rails.root}/test/fixtures/files/JERM-test.rdf"
      Settings.defaults[:assay_type_ontology_file] = "file:#{Rails.root}/test/fixtures/files/JERM-test.rdf"

      Settings.defaults[:doi_minting_enabled]=true
      Settings.defaults[:doi_prefix] = "10.5072"
      Settings.defaults[:doi_suffix] = "Sysmo.SEEK"
      Settings.defaults[:datacite_url] = "https://test.datacite.org/mds/"
      Settings.defaults[:datacite_username] = 'test'
      Settings.defaults[:datacite_password] = 'test'
      Settings.defaults[:time_lock_doi_for] = 0

      Seek::Config.fixed :css_prepended,''
      Seek::Config.fixed :css_appended,''
      Seek::Config.fixed :main_layout,'application'

      Settings.defaults[:faceted_browsing_enabled] = false
      Settings.defaults[:facet_enable_for_pages] = {:people => true, :projects => false, :institutions => false, :programmes => false, :investigations => false,:studies => false, :assays => true, :data_files => true, :models => true,:sops => true, :publications => true,:events => false, :strains => false, :presentations => false}
      Settings.defaults[:faceted_search_enabled] =  false

      Settings.defaults[:recaptcha_enabled] = true

      #enable solr for testing, but use mockup sunspot session
      Settings.defaults[:solr_enabled] = true
      Sunspot.session = SunspotMatchers::SunspotSessionSpy.new(Sunspot.session)

      Settings.defaults[:filtering_enabled] = true

      Settings.defaults[:imprint_enabled]= false
      Settings.defaults[:imprint_description]= 'Here is imprint example'

      Settings.defaults[:zenodo_publishing_enabled] = true
      Settings.defaults[:zenodo_api_url] = "https://sandbox.zenodo.org/api"
      Settings.defaults[:zenodo_oauth_url] = "https://sandbox.zenodo.org/oauth"

      Settings.defaults[:cache_remote_files] = true
      Settings.defaults[:max_cachable_size] = 2000
      Settings.defaults[:hard_max_cachable_size] = 5000

      Settings.defaults[:orcid_required] = false
      Settings.defaults[:site_base_host] = "http://localhost:3000"
      Settings.defaults[:session_store_timeout] = 30.minutes

      Settings.defaults[:default_all_visitors_access_type] = Policy::NO_ACCESS
      Settings.defaults[:max_all_visitors_access_type] = Policy::MANAGING

      Settings.defaults[:openbis_enabled] = true
      Settings.defaults[:openbis_debug] = false
      Settings.defaults[:openbis_autosync] = true
      Settings.defaults[:openbis_check_new_arrivals] = true

      Settings.defaults[:nels_enabled] = true
      Settings.defaults[:nels_api_url] = 'https://test-fe.cbu.uib.no/nels-api'
      Settings.defaults[:nels_oauth_url] = 'https://test-fe.cbu.uib.no/oauth2'
      Settings.defaults[:nels_permalink_base] = 'https://test-fe.cbu.uib.no/nels/pages/sbi/sbi.xhtml'
      Settings.defaults[:nels_use_dummy_client] = false
    end
  end
end

