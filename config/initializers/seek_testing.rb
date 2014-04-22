#Default values required for the automated unit, functional and integration testing to behave as expected.
SEEK::Application.configure do
  if Rails.env.test?
    silence_warnings do
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
      Settings.defaults[:publish_button_enabled] = true
      Settings.defaults[:auth_lookup_enabled] = false
      Settings.defaults[:sample_parser_enabled] = true
      Settings.defaults[:project_browser_enabled] = true
      Settings.defaults[:experimental_features_enabled] = true
      Settings.defaults[:filestore_path] = "tmp/testing-filestore"
      Settings.defaults[:tagging_enabled] = true
      Settings.defaults[:authorization_checks_enabled] = true
      Settings.defaults[:magic_guest_enabled] = false
      Settings.defaults[:workflows_enabled] = true

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

      Settings.defaults[:technology_type_ontology_file]= "file:#{Rails.root}/test/fixtures/files/JERM-test.rdf"
      Settings.defaults[:modelling_analysis_type_ontology_file]="file:#{Rails.root}/test/fixtures/files/JERM-test.rdf"
      Settings.defaults[:assay_type_ontology_file]="file:#{Rails.root}/test/fixtures/files/JERM-test.rdf"

      Seek::Config.fixed :css_prepended,''
      Seek::Config.fixed :css_appended,''
      Seek::Config.fixed :main_layout,'application'

      #force back to using the defaults
      ActionView::Renderer.clear_alternative({:controller=>:homes,:seek_template=>:index})
      ActionView::Renderer.clear_alternative({:seek_partial=>"people/resource_list_item"})
      ActionView::Renderer.clear_alternative({:seek_partial=>"projects/resource_list_item"})
      ActionView::Renderer.clear_alternative({:controller=>:people,:seek_partial=>"general/items_related_to"})
      ActionView::Renderer.clear_alternative({:controller=>:people,:seek_partial=>"general/items_related_to"})

      Settings.defaults[:faceted_browsing_enabled] = false

    end
  end
end

