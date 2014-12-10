#Default values required for the automated unit, functional and integration testing to behave as expected.
SEEK::Application.configure do
  if Rails.env.test?
    silence_warnings do
      Settings.defaults[:is_virtualliver] = false
      Settings.defaults[:project_hierarchy_enabled] = true
      Settings.defaults[:application_title] = 'The Sysmo SEEK'
      Settings.defaults[:project_name] = 'Sysmo'
      Settings.defaults[:project_title] = 'The Sysmo Consortium'

      Settings.defaults[:noreply_sender] ="no-reply@sysmo-db.org"
      Settings.defaults[:support_email_address] = 'support@seek.org'

      Settings.defaults[:crossref_api_email] = "sowen@cs.man.ac.uk"

      Settings.defaults[:jws_enabled] = true
      Settings.defaults[:events_enabled] = true
      Settings.defaults[:jws_online_root] = "http://jws2.sysmo-db.org"

      Settings.defaults[:email_enabled] = true
      Settings.defaults[:solr_enabled] = false

      Settings.defaults[:publish_button_enabled] = true
      Settings.defaults[:auth_lookup_enabled] = false
      Settings.defaults[:sample_parser_enabled] = true
      Settings.defaults[:project_browser_enabled] = true
      Settings.defaults[:experimental_features_enabled] = true
      Settings.defaults[:filestore_path] = "tmp/testing-filestore"
      Settings.defaults[:tagging_enabled] = true
      Settings.defaults[:authorization_checks_enabled] = true
      Settings.defaults[:magic_guest_enabled] = false
      Settings.defaults[:modelling_analysis_enabled] = true
      Settings.defaults[:workflows_enabled] = true
      Settings.defaults[:assays_enabled] = true
      Settings.defaults[:models_enabled] = true
      Settings.defaults[:show_as_external_link_enabled] = false
      Settings.defaults[:biosamples_enabled] = true
      Settings.defaults[:publications_enabled] = true
      Settings.defaults[:factors_studied_enabled] = true
      Settings.defaults[:experimental_conditions_enabled] = true
      Settings.defaults[:programmes_enabled] = true
      Settings.defaults[:project_hierarchy_enabled] = true
      Settings.defaults[:tabs_lazy_load_enabled] = false

      Settings.defaults[:project_link] = 'http://www.sysmo.net'
      Settings.defaults[:application_name] = 'SEEK'
      Settings.defaults[:dm_project_name] = "SysMO-DB"
      Settings.defaults[:dm_project_link] = "http://www.sysmo-db.org"
      Settings.defaults[:project_type] = 'Consortium'
      Settings.defaults[:header_image_enabled] = true
      Settings.defaults[:header_image_title] =  "SysMO-DB"
      Settings.defaults[:header_image_link] = "http://www.sysmo-db.org"
      Settings.defaults[:header_image] = 'sysmo-db-logo_smaller.png'
      Settings.defaults[:bioportal_api_key]="fish"

      Settings.defaults[:technology_type_ontology_file] = "file:#{Rails.root}/test/fixtures/files/JERM-test.rdf"
      Settings.defaults[:modelling_analysis_type_ontology_file] = "file:#{Rails.root}/test/fixtures/files/JERM-test.rdf"
      Settings.defaults[:assay_type_ontology_file] = "file:#{Rails.root}/test/fixtures/files/JERM-test.rdf"

      Settings.defaults[:doi_minting_enabled]=true
      Settings.defaults[:doi_prefix] = "10.5072"
      Settings.defaults[:doi_suffix] = "Sysmo.SEEK"
      Settings.defaults[:datacite_url] = "https://test.datacite.org/mds/"
      Settings.defaults[:datacite_username] = 'test'
      Seek::Config.datacite_password_encrypt('test')
      Settings.defaults[:time_lock_doi_for] = 0

      Seek::Config.fixed :css_prepended,''
      Seek::Config.fixed :css_appended,''
      Seek::Config.fixed :main_layout,'application'

      #force back to using the defaults
      ActionView::Renderer.clear_alternative({:controller=>:homes,:seek_template=>:index})
      ActionView::Renderer.clear_alternative({:seek_partial=>"people/resource_list_item"})
      ActionView::Renderer.clear_alternative({:seek_partial=>"projects/resource_list_item"})
      ActionView::Renderer.clear_alternative({:seek_partial=>"assets/sharing_form"})
      ActionView::Renderer.clear_alternative({:controller=>:people,:seek_partial=>"general/items_related_to"})


      Settings.defaults[:faceted_browsing_enabled] = false
      Settings.defaults[:facet_enable_for_pages] = {:specimens => false,:samples => false, :people => true, :projects => false, :institutions => false, :programmes => false, :investigations => false,:studies => false, :assays => true, :data_files => true, :models => true,:sops => true, :publications => true,:events => false, :strains => false, :presentations => false}
      Settings.defaults[:faceted_search_enabled] =  false

      Settings.defaults[:recaptcha_enabled] = true

      #enable solr for testing, but use mockup sunspot session
      Settings.defaults[:solr_enabled] = true
      Sunspot.session = SunspotMatchers::SunspotSessionSpy.new(Sunspot.session)


    end
  end
end

