SEEK::Application.routes.draw do
  resources :observed_variable_sets
  resources :observed_variables
  use_doorkeeper do
    controllers applications: 'oauth_applications'
    controllers authorized_applications: 'authorized_oauth_applications'
    controllers authorizations: 'oauth_authorizations'
  end
  mount MagicLamp::Genie, at: (SEEK::Application.config.relative_url_root || '/') + 'magic_lamp' if defined?(MagicLamp)
  # mount Teaspoon::Engine, :at => (SEEK::Application.config.relative_url_root || "/") + "teaspoon" if defined?(Teaspoon)

  # TRS
  namespace :ga4gh do
    namespace :trs do
      namespace :v2 do
        get 'tools' => 'tools#index'
        get 'tools/:id' => 'tools#show'
        get 'tools/:id/versions' => 'tool_versions#index'
        get 'tools/:id/versions/:version_id' => 'tool_versions#show', as: :tool_version
        get 'tools/:id/versions/:version_id/containerfile' => 'tool_versions#containerfile'
        get 'tools/:id/versions/:version_id/:type/descriptor(/*relative_path)' => 'tool_versions#descriptor', constraints: { relative_path: /.+/ }, format: false, as: :tool_versions_descriptor
        get 'tools/:id/versions/:version_id/:type/files' => 'tool_versions#files', format: false
        get 'tools/:id/versions/:version_id/:type/tests' => 'tool_versions#tests'
        get 'toolClasses' => 'general#tool_classes'
        get 'service-info' => 'general#service_info'
        get 'extended/workflows/:organization' => 'tools#index'
        get 'extended/organizations' => 'general#organizations'
      end
    end
  end

  # Concerns
  concern :has_content_blobs do
    member do
      get :download
    end
    resources :content_blobs do
      member do
        get :view_content
        get :get_pdf
        get :download
        delete :destroy
      end
    end
  end

  concern :has_dashboard do |stats_options|
    resources :stats, stats_options.reverse_merge(only: []) do
      collection do
        get :dashboard
        get :contributions
        get :asset_activity
        get :contributors
        get :asset_accessibility
        post :clear_cache
      end
    end
  end

  concern :publishable do
    member do
      post :check_related_items
      post :check_gatekeeper_required
      get :published
      post :publish_related_items
      post :publish
    end
  end

  concern :explorable_spreadsheet do
    member do
      get :explore
    end
  end
  concern :has_versions do
    member do
      post :create_version
      post :edit_version
      delete :destroy_version
    end
  end

  concern :has_snapshots do
    resources :snapshots, only: [:show, :new, :create, :destroy], concerns: [:has_doi] do
      member do
        get :download
        get :export, action: :export_preview
        post :export, action: :export_submit
      end
    end
  end

  concern :has_doi do
    member do
      get :mint_doi_confirm
      post :mint_doi
    end
  end

  concern :asset do
    collection do
      get :typeahead
      get :preview
    end
    member do
      post :request_contact
      post :update_annotations_ajax
      get :manage
      patch :manage_update
    end
  end

  concern :isa do
    collection do
      get :typeahead
      get :preview
    end
    member do
      post :update_annotations_ajax
      get :manage
      patch :manage_update
      get :new_object_based_on_existing_one
    end
  end

  concern :git do
    nested do
      scope controller: :git, path: '/git(/*version)', constraints: { path: /[^\0]+/ }, format: false do
        get 'tree(/*path)' => 'git#tree', as: :git_tree
        get 'blob/*path' => 'git#blob', as: :git_blob
        get 'raw/*path' => 'git#raw', as: :git_raw
        get 'download/*path' => 'git#download', as: :git_download
        get 'browse' => 'git#browse', as: :git_browse
        post 'blob(/*path)' =>'git#add_file', as: :git_add_file
        delete 'blob/*path' => 'git#remove_file', as: :git_remove_file
        patch 'blob/*path' => 'git#move_file', as: :git_move_file
        get 'freeze' => 'git#freeze_preview', as: :git_freeze_preview
        post 'freeze' => 'git#freeze', as: :git_freeze
        patch '' => 'git#update', as: :git_update_version
      end
    end
  end

  concern :has_avatar do
    resources :avatars do
      member do
        post :select
      end
    end
  end

  ### GENERAL PAGES ###

  root to: 'homes#index'

  resource :admin, controller: 'admin' do
    collection do
      get :index
      get :tags
      get :features_enabled
      get :rebrand
      get :home_settings
      get :pagination
      get :settings
      get :get_stats
      get :registration_form
      get :edit_tag
      post :update_home_settings
      post :delete_carousel_form
      post :restart_server
      post :restart_delayed_job
      post :update_admins
      post :update_rebrand
      post :test_email_configuration
      post :update_settings
      post :update_features_enabled
      post :update_pagination
      post :delete_tag
      post :edit_tag
      post :update_imprint_setting
      post :clear_failed_jobs
      post :clear_cache
    end
    concerns :has_dashboard, controller: :stats
  end

  resource :home do
    member do
      get :index
      get :feedback
      get :funding
      post :send_feedback
      get :imprint
      get :terms
      get :privacy
      get :about
      get :create_or_join_project
      get :report_issue
    end
  end

  get 'funding' => 'homes#funding', as: :funding
  get 'index.html' => 'homes#index'
  get 'index' => 'homes#index'

  resources :extended_metadata_types do
    collection do
      get :form_fields
      get :administer
    end
    member do
      put :administer_update
    end
  end

  resource :favourites do
    collection do
      post :add
    end
    member do
      delete :delete
    end
  end

  resources :help, controller: 'help_documents', as: :help_documents do
    resources :attachments, controller: 'help_attachments', as: :help_attachments, only: [:create, :destroy] do
      member do
        get :download
      end
    end
    resources :images, controller: 'help_images', as: :help_images, only: [:create, :destroy] do
      member do
        get :view
      end
    end
  end
  resources :help_attachments, only: [:create, :destroy] do
    member do
      get :download
    end
  end
  resources :help_images, only: [:create, :destroy] do
    member do
      get :view
    end
  end

  resources :avatars
  resources :attachments
  resources :subscriptions
  resources :saved_searches
  resources :uuids

  # resources :project_folders

  ### USERS AND SESSIONS ###

  resources :users do
    collection do
      get :activation_required
      get :forgot_password
      get :reset_password
      post :forgot_password
      post :hide_guide_box
      post :impersonate
      post :cancel_registration
      post :bulk_destroy
    end
    member do
      put :set_openid
      post :resend_activation_email
      post :activate, to: 'users#activate_other', as: 'activate_other'
    end
    resources :oauth_sessions, only: [:index, :destroy]
    resources :identities, only: [:index, :destroy]
    resources :api_tokens, only: [:index, :create, :destroy]
  end

  resource :session do
    collection do
      get :index
      get :show
      get :auto_openid
    end
    member do
      get :show
    end
  end

  ### YELLOW PAGES ###

  resources :people, concerns: [:publishable, :has_avatar] do
    collection do
      get :typeahead
      get :register
      get :current
      get :is_this_you
      get :get_work_group
      post :userless_project_selected_ajax
      post :bulk_destroy
    end
    member do
      get :batch_publishing_preview
      get :requested_approval_assets
      post :gatekeeper_decide
      get :gatekeeper_decision_result
      get :waiting_approval_assets
      post :cancel_publishing_request
      get :select
      get :items
      get :batch_sharing_permission_preview
      post :batch_change_permission_for_selected_items
      post :batch_sharing_permission_changed
    end
    resources :projects, :programmes, :institutions, :assays, :studies, :investigations, :models, :sops, :workflows,
              :data_files, :presentations, :publications, :documents, :events, :sample_types, :samples, :specimens,
              :strains, :file_templates, :placeholders, :collections, :templates, only: [:index]
  end

  resources :projects, concerns: [:has_avatar] do
    collection do
      get :request_institutions
      get :guided_join
      get :guided_create
      get :guided_import
      post :request_join
      post :request_create
      post :request_import
      get :administer_create_project_request
      get :administer_import_project_request
      post :respond_create_project_request
      post :respond_import_project_request
      get :project_join_requests
      get :project_creation_requests
      get :project_importation_requests
      get  :typeahead
    end
    member do
      get :asset_report
      get :populate
      post :populate_from_spreadsheet
      get :admin_members
      get :admin_member_roles
      get :storage_report
      post :update_members
      post :request_membership
      get :overview
      get :order_investigations
      get :administer_join_request
      post :respond_join_request
      get :guided_join
      post :update_annotations_ajax
    end
    resources :programmes, :people, :institutions, :assays, :studies, :investigations, :models, :sops, :workflows, :data_files, :presentations,
              :publications, :events, :sample_types, :samples, :specimens, :strains, :search, :organisms, :human_diseases, :documents, :file_templates, :placeholders, :collections, :templates, only: [:index]

    resources :openbis_endpoints do
      collection do
        get :test_endpoint
        get :fetch_spaces
        get :browse
      end
    end
    resources :folders do
      collection do
        post :nuke
      end
      member do
        post :remove_asset
        get :display_contents
        post :move_asset_to
        post :create_folder
        post :set_project_folder_title
        post :set_project_folder_description
      end
    end
    concerns :has_dashboard, controller: :project_stats
  end

  resources :openbis_endpoints do
    get :test_endpoint, on: :member
    get :fetch_spaces, on: :member
    get :refresh, on: :member
    get :reset_fatals, on: :member
    resources :openbis_experiments do
      get :refresh, on: :member
      post :register, on: :member
      post :batch_register, on: :collection
    end
    resources :openbis_zamples do
      get :refresh, on: :member
      post :register, on: :member
      post :batch_register, on: :collection
    end
    resources :openbis_datasets do
      get :refresh, on: :member
      post :register, on: :member
      get :show_dataset_files, on: :member
      post :batch_register, on: :collection
    end
  end

  resources :institutions, concerns: [:has_avatar] do
    collection do
      get :request_all
      get :request_all_sharing_form
      get  :typeahead
    end
    resources :people, :programmes, :projects, :specimens, only: [:index]
  end

  ### ISA ###

  resources :investigations, concerns: [:publishable, :has_snapshots, :isa] do
    resources :people, :programmes, :projects, :assays, :studies, :models, :sops, :workflows, :data_files, :publications, :documents, only: [:index]
    member do
      get :export_isatab_json
      get :export_isa, action: :export_isa
      get :manage
      get :order_studies
      patch :manage_update
    end
  end

  resources :studies, concerns: [:publishable, :has_snapshots, :isa] do
    collection do
      get :preview
      get :batch_uploader
      post :preview_content
      post :batch_create
      post :create_content_blob
      post :investigation_selected_ajax
    end
    resources :snapshots, :only => [:show, :new, :create, :destroy] do
      member do
        get :mint_doi_confirm
        post :mint_doi
        get :download
        get :export, action: :export_preview
        post :export, action: :export_submit
      end
    end
    member do
      get :new_object_based_on_existing_one
      post :check_related_items
      post :check_gatekeeper_required
      post :publish_related_items
      post :publish
      get :published
      get :isa_children
      get :manage
      get :order_assays
      patch :manage_update
    end
    resources :people, :programmes, :projects, :sample_types, :assays, :investigations, :models, :sops, :workflows, :data_files, :publications, :documents, only: [:index]
  end

  resources :assays, concerns: [:publishable, :has_snapshots, :isa] do
    resources :nels, only: [:index] do
      collection do
        get :projects
        get :datasets
        get :dataset
        post :register
      end
    end
    resources :people, :programmes, :projects, :investigations, :sample_types, :samples, :studies, :models, :sops, :workflows, :data_files, :publications, :documents, :strains, :organisms, :human_diseases, :placeholders, only: [:index]
  end

  # to be removed as STI does not work in too many places
  # resources :openbis_assays, controller: 'assays', type: 'OpenbisAssay'

  ### ASSAY AND TECHNOLOGY TYPES ###

  resources :suggested_assay_types
  resources :suggested_modelling_analysis_types, path: :suggested_assay_types, controller: :suggested_assay_types
  resources :suggested_technology_types

  ### ASSETS ###

  resources :data_files, concerns: [:has_content_blobs, :has_versions, :has_doi, :publishable, :asset, :explorable_spreadsheet] do
    collection do
      get :filter
      get :provide_metadata
      post :create_content_blob
      post :rightfield_extraction_ajax
      post :create_metadata
    end
    member do
      get :samples_table
      get :select_sample_type
      get :confirm_extraction
      get :extraction_status
      get :persistence_status
      post :extract_samples
      delete :cancel_extraction
      get :destroy_samples_confirm
      post :retrieve_nels_sample_metadata
      get :retrieve_nels_sample_metadata
      get :has_matching_sample_type
    end
    resources :people, :programmes, :projects, :investigations, :assays, :samples, :studies, :publications, :events, :collections, :workflows, :file_templates, :placeholders, only: [:index]
  end

  resources :presentations, concerns: [:has_content_blobs, :publishable, :has_versions, :asset, :explorable_spreadsheet] do
    resources :people, :programmes, :projects, :publications, :events, :collections, :workflows, :investigations, :studies, :assays, only: [:index]
  end

  resources :models, concerns: [:has_content_blobs, :publishable, :has_doi, :has_versions, :asset] do
    member do
      get :compare_versions
      post :compare_versions
      post :submit_to_sycamore
      post :execute
      get :simulate
      post :simulate
    end
    resources :model_images, only: [:show]
    resources :people, :programmes, :projects, :investigations, :assays, :studies, :publications, :events, :collections, :organisms, :human_diseases, only: [:index]
  end

  resources :sops, concerns: [:has_content_blobs, :publishable, :has_doi, :has_versions, :asset, :explorable_spreadsheet] do
    resources :people, :programmes, :projects, :investigations, :assays, :samples, :studies, :publications, :events, :workflows, :collections, only: [:index]
  end

  resources :workflows, concerns: [:has_content_blobs, :publishable, :has_doi, :has_versions, :asset, :git] do
    collection do
      post :create_from_ro_crate
      post :create_from_files
      post :create_from_git
      get :provide_metadata
      get :annotate_repository
      post :create_metadata
      get :filter
      post :create_content_blob # Legacy
      post :create_ro_crate # Legacy
    end
    member do
      get :diagram
      get :ro_crate
      get :ro_crate_metadata
      get :new_version
      get :new_git_version
      post :create_version_metadata
      post :create_version_from_git
      get :edit_paths
      patch :update_paths
    end
    resources :people, :programmes, :projects, :investigations, :assays, :samples, :studies, :publications, :events, :sops, :collections, :presentations, :documents, :data_files, only: [:index]
  end

  resources :workflow_classes, except: [:show], concerns: [:has_avatar]

  resources :file_templates, concerns: [:has_content_blobs, :has_versions, :has_doi, :publishable, :asset, :explorable_spreadsheet] do
    collection do
      get :filter
      get :provide_metadata
      post :create_content_blob
      post :create_metadata
    end
    resources :people, :programmes, :projects, :collections, :investigations, :studies, :assays, :data_files, :publications, :placeholders, only: [:index]
  end

  resources :placeholders, concerns: [:asset, :explorable_spreadsheet] do
    collection do
      get :filter
      get :provide_metadata
      post :create_metadata
    end
    member do
      get :data_file
    end
    resources :people, :programmes, :projects, :collections, :investigations, :studies, :assays, :data_files, :publications, :file_templates, only: [:index]
  end

  resources :content_blobs, except: [:show, :index, :update, :create, :destroy] do
    collection do
      post :examine_url
    end
  end
  resources :programmes, concerns: [:has_avatar] do
    collection do
      get :awaiting_activation
    end
    member do
      get :activation_review
      put :accept_activation
      put :reject_activation
      get :reject_activation_confirmation
      get :storage_report
    end
    resources :people, :projects, :institutions, :investigations, :studies, :assays, :samples,
              :data_files, :models, :sops, :workflows, :presentations, :documents, :events, :publications, :organisms, :human_diseases, :collections, only: [:index]
    concerns :has_dashboard, controller: :programme_stats
  end

  resources :publications, concerns: [:asset, :has_content_blobs] do
    collection do
      get :query_authors
      get :query_authors_typeahead
      get :export
      post :fetch_preview
      post :update_metadata
    end
    member do
      get :manage
      get :download
      get :upload_fulltext
      get :soft_delete_fulltext
      post :update_annotations_ajax
      post :disassociate_authors
      post :update_metadata
      post :request_contact
      post :upload_pdf
    end
    resources :people, :programmes, :projects, :investigations, :assays, :studies, :models, :data_files, :documents, :presentations, :organisms, :events, :collections, :workflows, :human_diseases, only: [:index]
  end

  resources :events, concerns: [:asset] do
    resources :people, :programmes, :projects, :data_files, :publications, :documents, :presentations, :collections, only: [:index]
  end

  resource :policies do
    collection do
      post :preview_permissions
    end
  end

  resources :strains, concerns: [:asset] do
    collection do
      get :existing_strains_for_assay_organism
      get :strains_of_selected_organism
    end
    resources :specimens, :assays, :people, :programmes, :projects, :samples, :organisms, only: [:index]
  end

  resources :organisms do
    collection do
      post :search_ajax
    end
    resources :projects, :programmes, :assays, :studies, :models, :strains, :specimens, :samples, :publications, only: [:index]
  end

  resources :human_diseases do
    collection do
      post :search_ajax
    end
    resources :projects, :programmes, :assays, :studies, :models, :publications, only: [:index]
    member do
      get :tree
    end
  end

  resources :tissue_and_cell_types
  resources :statistics do
    collection do
      get :application_status
    end
  end

  resources :site_announcements do
    collection do
      get :feed
      get :notification_settings
      post :update_notification_settings
    end
  end

  ### SAMPLES ###

  resources :samples, concerns: [:asset] do
    collection do
      get :attribute_form
      get :filter
      post :batch_create
      put :batch_update
      delete :batch_delete
      get :query_form
      post :query
    end
    resources :people, :programmes, :projects, :assays, :studies, :investigations, :data_files, :publications, :samples,
              :sample_types, :strains, :organisms, :collections, only: [:index]
  end

  ### SAMPLE TYPES ###
  #
  resources :sample_types do
    collection do
      post :create_from_template
      get :select
      get :filter_for_select
    end
    member do
      get :template_details
      get :batch_upload
    end
    resources :samples
    resources :content_blobs do
      member do
        get :download
      end
    end
    resources :projects, :programmes, :templates, :studies, :assays, only: [:index]
  end

  ### SAMPLE ATTRIBUTE TYPES ###

  resources :sample_attribute_types, only: [:index, :show]

  ### SAMPLE CONTROLLED VOCABS ###

  resources :sample_controlled_vocabs do
    collection do
      get :typeahead
      get :fetch_ols_terms_html
    end
  end

  ### DOCUMENTS

  resources :documents, concerns: [:has_content_blobs, :publishable, :has_doi, :has_versions, :asset, :explorable_spreadsheet] do
    resources :people, :programmes, :projects, :programmes, :investigations, :assays, :studies, :publications, :events, :collections, :workflows, only: [:index]
  end

  resources :collections, concerns: [:publishable, :has_doi, :asset, :has_avatar] do
    resources :items, controller: :collection_items
    resources :people, :programmes, :projects, :programmes, :investigations, :assays, :studies, :publications, :events, :collections, only: [:index]
  end

  resources :git_repositories, only: [] do
    member do
      get :status
      get :refs
    end
  end

  resources :creators, only: [] do
    collection do
      get :registered
      get :unregistered
    end
  end

  ### TEMPLATES ###
  resources :templates do
    resources :projects, only: [:index]
    member do
      get :manage
      patch :manage_update
      post :template_attributes
    end
    collection do
      post :filter_isa_tags_by_level
      get :task_status
      get :default_templates
      post :populate_template
    end
    resources :samples
    resources :projects, :people, :programmes, :investigations, :studies, :sample_types, :assays, :publications, :collections,  only: [:index]
  end

  ### SINGLE PAGE
  resources :single_pages do
    member do
      get :dynamic_table_data
      post :update_annotations_ajax
    end
    collection do
      get :batch_sharing_permission_preview
      post :batch_change_permission_for_selected_items
      post :batch_sharing_permission_changed
      post :export_to_excel, action: :export_to_excel
      get :download_samples_excel, action: :download_samples_excel
      post :upload_samples, action: :upload_samples
    end
  end

  ### ISA STUDY
  resources :isa_studies do
  end

  ### ISA ASSAY
  resources :isa_assays do
  end

  resources :culture_growth_types, only: [:show]

  resources :tools, only: [] do
    collection do
      get :filter
    end
  end

  ### ASSAY AND TECHNOLOGY TYPES ###

  get '/assay_types/', to: 'assay_types#show', as: 'assay_types'
  get '/modelling_analysis_types/', to: 'assay_types#show', as: 'modelling_analysis_types'
  get '/technology_types/', to: 'technology_types#show', as: 'technology_types'

  ### MISC MATCHES ###
  get '/search/' => 'search#index', as: :search
  get '/search/save' => 'search#save', as: :save_search
  get '/search/delete' => 'search#delete', as: :delete_search
  get 'svg/:id.:format' => 'svg#show', as: :svg
  get '/tags/query' => 'tags#query', as: :query_tags
  get '/tags' => 'tags#index', as: :all_tags
  get '/tags/:id' => 'tags#show', as: :show_tag
  get '/tags' => 'tags#index', as: :all_anns
  get '/tags/:id' => 'tags#show', as: :show_ann
  get '/countries/:country_code' => 'countries#show', as: :country

  get '/data_fuse/' => 'data_fuse#show', as: :data_fuse
  post '/favourite_groups/new' => 'favourite_groups#new', as: :new_favourite_group
  post '/favourite_groups/create' => 'favourite_groups#create', as: :create_favourite_group
  post '/favourite_groups/edit' => 'favourite_groups#edit', as: :edit_favourite_group
  post '/favourite_groups/update' => 'favourite_groups#update', as: :update_favourite_group
  delete '/favourite_groups/:id' => 'favourite_groups#destroy', as: :delete_favourite_group
  post 'experiments/create_investigation' => 'studies#create_investigation', as: :create_investigation

  get '/signup' => 'users#new', as: :signup

  get '/logout' => 'sessions#destroy', as: :logout
  get '/login' => 'sessions#new', as: :login
  get '/create' => 'sessions#create', as: :create_session
  # Omniauth
  post '/auth/:provider' => 'sessions#create', as: :omniauth_authorize # For security, ONLY POST should be enabled on this route.
  match '/auth/:provider/callback' => 'sessions#create', as: :omniauth_callback, via: [:get, :post] # Callback routes need both GET and POST enabled.
  match '/identities/auth/:provider/callback' => 'sessions#create', as: :legacy_omniauth_callback, via: [:get, :post] # Needed for legacy support..
  get '/auth/failure' => 'sessions#omniauth_failure', as: :omniauth_failure

  get '/activate(/:activation_code)' => 'users#activate', as: :activate
  get '/forgot_password' => 'users#forgot_password', as: :forgot_password
  get '/policies/request_settings' => 'policies#send_policy_data', as: :request_policy_settings
  get '/fail' => 'fail#index', as: :fail

  get '/whoami' => 'users#whoami'

  # feedback
  get '/home/feedback' => 'homes#feedback', as: :feedback

  # error rendering
  get '/404' => 'errors#error_404'
  get '/406' => 'errors#error_406'
  get '/422' => 'errors#error_422'
  get '/500' => 'errors#error_500'
  get '/503' => 'errors#error_503'

  get '/zenodo_oauth_callback' => 'zenodo/oauth2/callbacks#callback'
  get '/seek_nels' => 'nels#callback', as: 'nels_oauth_callback'

  get '/citation/(*doi)' => 'citations#fetch', as: :citation, constraints: { doi: /.+/ }

  get '/home/isa_colours' => 'homes#isa_colours'

  post '/previews/markdown' => 'previews#markdown'

  # cookie consent
  get 'cookies/consent' => 'cookies#consent'
  post 'cookies/consent' => 'cookies#set_consent'

  # for the api docs under production, avoids special rewrite rules
  get 'api', to: static("api/index.html") if Rails.env.production?
end
