SEEK::Application.routes.draw do

  mount MagicLamp::Genie, :at => (SEEK::Application.config.relative_url_root || "/") + 'magic_lamp'  if defined?(MagicLamp)
  #mount Teaspoon::Engine, :at => (SEEK::Application.config.relative_url_root || "/") + "teaspoon" if defined?(Teaspoon)

  # Concerns
  concern :has_content_blobs do
    resources :content_blobs do
      member do
        get :view_pdf_content
        get :view_content
        get :get_pdf
        get :download
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

  resources :scales do
    collection do
      post :search
    end
  end

  ### GENERAL PAGES ###

  root :to => "homes#index"

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
    end
  end

  get 'funding' => 'homes#funding', :as => :funding
  get 'index.html' => 'homes#index'
  get 'index' => 'homes#index'

  resource :favourites do
    collection do
      post :add
    end
    member do
      delete :delete
    end
  end

  resources :help, controller: 'help_documents', as: :help_documents do
    resources :attachments, controller: 'help_attachments', as: :help_attachments,only: [:create,:destroy] do
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
  resources :help_attachments, only: [:create,:destroy] do
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
  resources :measured_items
  resources :saved_searches
  resources :uuids
  resources :compounds do
    collection do
      post :search_in_sabiork
    end
  end

  #resources :project_folders

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
    end
    resources :oauth_sessions, only: [:index, :destroy]
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

  resources :people do
    collection do
      get :typeahead
      get :register
      get :is_this_you
      get :get_work_group
      post :userless_project_selected_ajax
      post :items_for_result
      post :bulk_destroy
    end
    member do
      post :check_related_items
      post :check_gatekeeper_required
      get :published
      get :batch_publishing_preview
      post :publish_related_items
      post :publish
      get :requested_approval_assets
      post :gatekeeper_decide
      get :gatekeeper_decision_result
      get :waiting_approval_assets
      get :select
      get :items
    end
    resources :projects,:institutions,:assays,:studies,:investigations,:models,:sops,:workflows,:nodes, :data_files,:presentations,:publications,:documents, :events,:samples,:specimens, :strains, :only=>[:index]
    resources :avatars do
      member do
        post :select
      end
    end
  end

  resources :projects do
    collection do
      get :request_institutions
      get :manage
      post :items_for_result
    end
    member do
      get :asset_report
      get :admin
      get :admin_members
      get :admin_member_roles
      get :storage_report
      post :update_members
      post :request_membership
      get :isa_children
      get :overview
    end
    resources :people,:institutions,:assays,:studies,:investigations,:models,:sops,:workflows,:nodes, :data_files,:presentations,
              :publications,:events,:samples,:specimens,:strains,:search,:organisms,:documents, :only=>[:index]

    resources :openbis_endpoints do
      collection do
        get :test_endpoint
        get :fetch_spaces
        get :browse
      end
    end
    resources :avatars do
      member do
        post :select
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

  resources :institutions do
    collection do
      get :request_all
      post :items_for_result
    end
    resources :people,:projects,:specimens,:only=>[:index]
    resources :avatars do
      member do
        post :select
      end
    end
  end

  ### ISA ###

  resources :investigations do
    collection do
      get :preview
      post :items_for_result
    end
    resources :people,:projects,:assays,:studies,:models,:sops,:workflows, :nodes,:data_files,:publications, :documents, :only=>[:index]
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
      patch :manage_update
    end
  end

  resources :studies do
    collection do
      get :preview
      post :investigation_selected_ajax
      post :items_for_result
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
      patch :manage_update
    end
    resources :people,:projects,:assays,:investigations,:models,:sops,:workflows,:nodes,:data_files,:publications, :documents,:only=>[:index]
  end

  resources :assays do
    collection do
      get :typeahead
      get :preview
      post :items_for_result
      #MERGENOTE - these should be gets and are tested as gets, using post to fix later
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
    resources :nels, only: [:index] do
      collection do
        get :projects
        get :datasets
        get :dataset
        post :register
      end
    end
    member do
      post :update_annotations_ajax
      post :check_related_items
      post :check_gatekeeper_required
      post :publish_related_items
      post :publish
      get :published
      get :new_object_based_on_existing_one
      get :isa_children
      get :manage
      patch :manage_update
    end
    resources :people,:projects,:investigations,:samples, :studies,:models,:sops,:workflows,:nodes,:data_files,:publications, :documents,:strains,:organisms, :only=>[:index]
  end

  # to be removed as STI does not work in too many places
  # resources :openbis_assays, controller: 'assays', type: 'OpenbisAssay'

   ### ASSAY AND TECHNOLOGY TYPES ###

  resources :suggested_assay_types
  resources :suggested_modelling_analysis_types, :path => :suggested_assay_types, :controller => :suggested_assay_types
  resources :suggested_technology_types

  ### ASSETS ###

  resources :data_files, concerns: [:has_content_blobs] do
    collection do
      get :typeahead
      get :preview
      get :filter
      post :test_asset_url
      post :upload_for_tool
      post :upload_from_email
      post :items_for_result
      get :provide_metadata
      post :create_content_blob
      post :rightfield_extraction_ajax
      post :create_metadata
    end
    member do
      post :check_gatekeeper_required
      get :plot
      get :explore
      get :download
      get :published
      post :check_related_items
      post :publish_related_items
      post :publish
      post :request_resource
      post :update_annotations_ajax
      post :new_version
      post :edit_version_comment
      #MERGENOTE - this is a destroy, and should be the destroy method, not post since we are not updating or creating something.
      post :destroy_version
      get :mint_doi_confirm
      post :mint_doi
      get :samples_table
      get :select_sample_type
      get :confirm_extraction
      get :extraction_status
      post :extract_samples
      delete :cancel_extraction
      get :isa_children
      get :destroy_samples_confirm
      post :retrieve_nels_sample_metadata
      get :retrieve_nels_sample_metadata
      get :manage
      patch :manage_update
    end
    resources :studied_factors do
      collection do
        post :create_from_existing
      end
    end
    resources :people,:projects,:investigations,:assays, :samples, :studies,:publications,:events,:only=>[:index]
  end

  resources :presentations, concerns: [:has_content_blobs] do
    collection do
      get :typeahead
      get :preview
      post :test_asset_url
      post :items_for_result
    end
    member do
      post :check_related_items
      post :check_gatekeeper_required
      get :download
      get :published
      post :publish_related_items
      post :publish
      post :request_resource
      post :update_annotations_ajax
      post :new_version
      post :edit_version_comment
      delete :destroy_version
      get :isa_children
      get :manage
      patch :manage_update
    end
    resources :people,:projects,:publications,:events,:only=>[:index]
  end

  resources :models, concerns: [:has_content_blobs] do
    collection do
      get :typeahead
      get :preview
      post :test_asset_url
      post :items_for_result
    end
    member do
      get :compare_versions
      post :compare_versions
      post :check_related_items
      get :visualise
      post :check_gatekeeper_required
      get :download
      get :published
      post :publish_related_items
      post :new_version
      post :edit_version_comment
      post :submit_to_sycamore
      post :export_as_xgmml
      post :update_annotations_ajax
      post :publish
      post :execute
      post :request_resource
      get :simulate
      post :simulate
      delete :destroy_version
      post :mint_doi
      get :mint_doi_confirm
      get :isa_children
      get :manage
      patch :manage_update
    end
    resources :model_images do
      collection do
        post :new
      end
      member do
        post :select
      end
    end
    resources :people,:projects,:investigations,:assays,:studies,:publications,:events,:only=>[:index]
  end

  resources :sops, concerns: [:has_content_blobs] do
    collection do
      get :typeahead
      get :preview
      post :test_asset_url
      post :items_for_result
    end
    member do
      post :check_related_items
      post :check_gatekeeper_required
      get :download
      get :published
      post :publish_related_items
      post :publish
      post :request_resource
      post :update_annotations_ajax
      post :new_version
      post :edit_version_comment
      delete :destroy_version
      post :mint_doi
      get :mint_doi_confirm
      get :isa_children
      get :manage
      patch :manage_update
    end
    resources :experimental_conditions do
      collection do
        post :create_from_existing
      end
    end
    resources :people,:projects,:investigations,:assays,:samples,:studies,:publications,:events,:only=>[:index]
  end

  resources :workflows, concerns: [:has_content_blobs] do
    collection do
      get :typeahead
      get :preview
      post :test_asset_url
      post :items_for_result
      post :resource_in_tab
    end
    member do
      post :check_related_items
      post :check_gatekeeper_required
      get :download
      get :published
      post :publish_related_items
      post :publish
      post :request_resource
      post :update_annotations_ajax
      post :new_version
      post :edit_version_comment
      delete :destroy_version
      post :mint_doi
      get :mint_doi_confirm
      get :isa_children
      get :manage
      patch :manage_update
    end
    resources :people,:projects,:investigations,:assays,:samples,:studies,:publications,:events,:only=>[:index]
  end

  resources :nodes, concerns: [:has_content_blobs] do
    collection do
      get :typeahead
      get :preview
      post :test_asset_url
      post :items_for_result
      post :resource_in_tab
    end
    member do
      post :check_related_items
      post :check_gatekeeper_required
      get :download
      get :published
      post :publish_related_items
      post :publish
      post :request_resource
      post :update_annotations_ajax
      post :new_version
      post :edit_version_comment
      delete :destroy_version
      post :mint_doi
      get :mint_doi_confirm
      get :isa_children
      get :manage
      patch :manage_update
    end
    resources :people,:projects,:investigations,:assays,:samples,:studies,:publications,:events,:only=>[:index]
  end

  resources :content_blobs, :except => [:show, :index, :update, :create, :destroy] do
    collection do
      post :examine_url
    end
  end
  resources :programmes do
    resources :avatars do
      member do
        post :select
      end
    end
    collection do
      post :items_for_result
      get :awaiting_activation
    end
    member do
      get :activation_review
      put :accept_activation
      put :reject_activation
      get :reject_activation_confirmation
      get :storage_report
      get :isa_children
    end
    resources :people,:projects, :institutions, :investigations, :studies, :assays,
              :data_files, :models, :sops, :workflows, :nodes, :presentations, :documents, :events, :publications, :organisms
  end

  resources :publications do
    collection do
      get :typeahead
      get :preview
      get :query_authors
      get :query_authors_typeahead
      get :export
      post :fetch_preview
      post :items_for_result
    end
    member do
      post :update_annotations_ajax
      post :disassociate_authors
    end
    resources :people,:projects,:investigations,:assays,:studies,:models,:data_files,:documents, :presentations, :organisms, :events,:only=>[:index]
  end

  resources :events do
    collection do
      get :typeahead
      get :preview
      post :items_for_result
    end
    member do
      get :manage
      patch :manage_update
    end
    resources :people,:projects,:data_files,:publications,:presentations,:only=>[:index]
  end

  resource :policies do
    collection do
      post :preview_permissions
    end
  end

  resources :spreadsheet_annotations, :only => [:create, :destroy, :update]


  resources :strains do
    collection do
      get :existing_strains_for_assay_organism
      get :strains_of_selected_organism
      post :items_for_result
    end
    member do
      post :update_annotations_ajax
      get :manage
      patch :manage_update
    end
    resources :specimens,:assays,:people,:projects,:samples,:only=>[:index]
  end

  resources :organisms do
    collection do
      post :search_ajax
    end
    resources :projects, :assays, :studies, :models, :strains, :specimens, :samples, :publications, :only=>[:index]
    member do
      get :visualise
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

  resources :samples do
    collection do
      get :attribute_form
      get :preview
      get :filter
    end
    member do
      post :update_annotations_ajax
      get :isa_children
      get :manage
      patch :manage_update
    end
    resources :people, :projects, :assays, :studies, :investigations, :data_files, :publications, :samples, only:[:index]
  end

  ### SAMPLE TYPES ###

  resources :sample_types do
    collection do
      post :create_from_template
      get :select
      get :filter_for_select
    end
    member do
      get :template_details
    end
    resources :samples
    resources :content_blobs do
      member do
        get :download
      end
    end
    resources :projects,only:[:index]
  end

  ### SAMPLE CONTROLLED VOCABS ###

  resources :sample_controlled_vocabs

  ### DOCUMENTS

  resources :documents, concerns: [:has_content_blobs] do
    collection do
      get :typeahead
      get :preview
      post :test_asset_url
      post :items_for_result
    end
    member do
      post :check_related_items
      post :check_gatekeeper_required
      get :download
      get :published
      post :publish_related_items
      post :publish
      post :request_resource
      post :update_annotations_ajax
      post :new_version
      post :edit_version_comment
      delete :destroy_version
      post :mint_doi
      get :mint_doi_confirm
      get :isa_children
      get :manage
      patch :manage_update
    end
    resources :people,:projects, :programmes,:investigations,:assays,:studies,:publications,:only=>[:index]
  end

  ### ASSAY AND TECHNOLOGY TYPES ###

  get '/assay_types/',:to=>"assay_types#show",:as=>"assay_types"
  get '/modelling_analysis_types/',:to=>"assay_types#show",:as=>"modelling_analysis_types"
  get '/technology_types/',:to=>"technology_types#show",:as=>"technology_types"


  ### MISC MATCHES ###
  get '/search/' => 'search#index', :as => :search
  get '/search/save' => 'search#save', :as => :save_search
  get '/search/delete' => 'search#delete', :as => :delete_search
  post '/search/items_for_result' => 'search#items_for_result'
  get 'svg/:id.:format' => 'svg#show', :as => :svg
  get '/tags/latest' => 'tags#latest', :as => :latest_tags
  get '/tags/query' => 'tags#query', :as => :query_tags
  get '/tags' => 'tags#index', :as => :all_tags
  get '/tags/:id' => 'tags#show', :as => :show_tag
  get '/tags' => 'tags#index', :as => :all_anns
  get '/tags/:id' => 'tags#show', :as => :show_ann
  get '/countries/:country_name' => 'countries#show', :as => :country

  get '/data_fuse/' => 'data_fuse#show', :as => :data_fuse
  post '/favourite_groups/new' => 'favourite_groups#new', :as => :new_favourite_group
  post '/favourite_groups/create' => 'favourite_groups#create', :as => :create_favourite_group
  post '/favourite_groups/edit' => 'favourite_groups#edit', :as => :edit_favourite_group
  post '/favourite_groups/update' => 'favourite_groups#update', :as => :update_favourite_group
  delete '/favourite_groups/:id' => 'favourite_groups#destroy', :as => :delete_favourite_group
  post 'experiments/create_investigation' => 'studies#create_investigation', :as => :create_investigation
  # get ':controller/:id/approve_or_reject_publish' => ":controller#show" # TODO: Rails4 - Delete me?

  get '/signup' => 'users#new', :as => :signup

  get '/logout' => 'sessions#destroy', :as => :logout
  get '/login' => 'sessions#new', :as => :login
  get '/auth/:provider/callback' => 'sessions#create'
  get '/activate(/:activation_code)' => 'users#activate', :as => :activate
  get '/forgot_password' => 'users#forgot_password', :as => :forgot_password
  get '/policies/request_settings' => 'policies#send_policy_data', :as => :request_policy_settings
  get '/fail'=>'fail#index',:as=>:fail

  #feedback
  get '/home/feedback' => 'homes#feedback', :as=> :feedback

  #error rendering
  get "/404" => "errors#error_404"
  get "/422" => "errors#error_422"
  get "/500" => "errors#error_500"
  get "/503" => "errors#error_503"

  get "/zenodo_oauth_callback" => "zenodo/oauth2/callbacks#callback"
  get "/seek_nels" => "nels#callback", as: 'nels_oauth_callback'

  get "/citation/(*doi)" => "citations#fetch", as: :citation, constraints: { doi: /.+/ }

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
  #
   get '/home/isa_colours' => 'homes#isa_colours'
end
