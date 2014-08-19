#Default values required for the automated unit, functional and integration testing to behave as expected.
SEEK::Application.configure do
  if Rails.env.test?
    silence_warnings do
      Seek::Config.fixed :is_virtualliver, false
      Settings.defaults[:application_title] = 'The Sysmo SEEK'
      Settings.defaults[:project_name] = 'Sysmo'
      Settings.defaults[:project_title] = 'The Sysmo Consortium'

      Settings.defaults[:noreply_sender] ="no-reply@sysmo-db.org"

      Settings.defaults[:crossref_api_email] = "sowen@cs.man.ac.uk"

      Settings.defaults[:jws_enabled] = true
      Settings.defaults[:events_enabled] = true
      Settings.defaults[:jws_online_root] = "http://jws.sysmo-db.org"

      Settings.defaults[:email_enabled] = true
      Settings.defaults[:solr_enabled] = false

      Seek::Config.fixed :publish_button_enabled, true
      Seek::Config.fixed :auth_lookup_enabled, false
      Seek::Config.fixed :sample_parser_enabled, true
      Seek::Config.fixed :project_browser_enabled, true
      Seek::Config.fixed :experimental_features_enabled, true
      Seek::Config.fixed :filestore_path, "tmp/testing-filestore"
      Seek::Config.fixed :tagging_enabled, true
      Seek::Config.fixed :authorization_checks_enabled, true
      Seek::Config.fixed :magic_guest_enabled, false
      Seek::Config.fixed :workflows_enabled, true
      Seek::Config.fixed :programmes_enabled, true
      Seek::Config.fixed :project_hierarchy_enabled, true

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

      Seek::Config.fixed :technology_type_ontology_file, "file:#{Rails.root}/test/fixtures/files/JERM-test.rdf"
      Seek::Config.fixed :modelling_analysis_type_ontology_file, "file:#{Rails.root}/test/fixtures/files/JERM-test.rdf"
      Seek::Config.fixed :assay_type_ontology_file, "file:#{Rails.root}/test/fixtures/files/JERM-test.rdf"

      Seek::Config.fixed :css_prepended,''
      Seek::Config.fixed :css_appended,''
      Seek::Config.fixed :main_layout,'application'

      #force back to using the defaults
      ActionView::Renderer.clear_alternative({:controller=>:homes,:seek_template=>:index})
      ActionView::Renderer.clear_alternative({:seek_partial=>"people/resource_list_item"})
      ActionView::Renderer.clear_alternative({:seek_partial=>"projects/resource_list_item"})
      ActionView::Renderer.clear_alternative({:controller=>:people,:seek_partial=>"general/items_related_to"})

      Seek::Config.fixed :faceted_browsing_enabled, false
      Seek::Config.fixed :facet_enable_for_pages, {:specimens => false,:samples => false, :people => true, :projects => false, :institutions => false, :programmes => false, :investigations => false,:studies => false, :assays => true, :data_files => true, :models => true,:sops => true, :publications => true,:events => false, :strains => false, :presentations => false}
      Seek::Config.fixed :faceted_search_enabled,  false

      #enable solr for testing, but use mockup sunspot session
      Seek::Config.solr_enabled = true
      Sunspot.session = SunspotMatchers::SunspotSessionSpy.new(Sunspot.session)

    end
  end
end

