SEEK::Application.routes.draw do

  resources :sample_types do
    collection do
      post :create_from_template
    end
    resources :samples
    resources :content_blobs do
      member do
        get :download
      end
    end
  end

  mount MagicLamp::Genie, :at => (SEEK::Application.config.relative_url_root || "/") + 'magic_lamp'  if defined?(MagicLamp)
  mount Teaspoon::Engine, :at => (SEEK::Application.config.relative_url_root || "/") + "teaspoon" if defined?(Teaspoon)

  mount TavernaPlayer::Engine, :at => (SEEK::Application.config.relative_url_root || "/")

  resources :scales do
    collection do
      post :search
      post :search_and_lazy_load_results
    end
  end


  ### GENERAL PAGES ###

  root :to => "homes#index"

  resource :admin do
    member do
      get :show
      get :tags
      get :features_enabled
      get :rebrand
      get :home_settings
      get :pagination
      get :others
      get :get_stats
      get :registration_form
      get :edit_tag
      get :imprint_setting
      post :update_home_settings
      post :restart_server
      post :restart_delayed_job
      post :get_stats
      post :get_user_stats
      post :update_admins
      post :update_rebrand
      post :test_email_configuration
      post :update_others
      post :update_features_enabled
      post :update_pagination
      post :delete_tag
      post :edit_tag
      post :update_imprint_setting
    end
  end

  resource :home do
    member do
      get :index
      get :feedback
      get :funding
      post :send_feedback
      get :imprint
    end
  end

  match 'funding' => 'homes#funding', :as => :match
  match 'index.html' => 'homes#index', :as => :match
  match 'index' => 'homes#index', :as => :match
  match 'my_biovel' => 'homes#my_biovel', :as => :my_biovel

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
    resources :images, controller: 'help_images', as: :help_images, only: [:create, :destroy]
  end
  resources :help_attachments, only: [:create,:destroy] do
    member do
      get :download
    end
  end
  resources :help_images, only: [:create, :destroy]

  resources :forum_attachments, :only => [:create, :destroy] do
    member do
      get :download
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
      post :resource_in_tab
      post :bulk_destroy
    end
    member do
      post :check_related_items
      post :check_gatekeeper_required
      get :admin
      get :published
      get :batch_publishing_preview
      post :publish_related_items
      put :administer_update
      post :publish
      get :requested_approval_assets
      post :gatekeeper_decide
      get :gatekeeper_decision_result
      get :waiting_approval_assets
      get :select
    end
    resources :projects,:institutions,:assays,:studies,:investigations,:models,:sops,:data_files,:presentations,:publications,:events,:samples,:specimens,:only=>[:index]
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
      post :resource_in_tab
    end
    member do
      get :asset_report
      get :admin
      get :admin_members
      get :admin_member_roles
      get :storage_report
      post :update_members
    end
    resources :people,:institutions,:assays,:studies,:investigations,:models,:sops,:data_files,:presentations,
              :publications,:events,:samples,:specimens,:strains,:only=>[:index]
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
        post :display_contents
        post :move_asset_to
        post :create_folder
        post :set_project_folder_title
        post :set_project_folder_description
      end
    end
  end

  resources :institutions do
    collection do
      get :request_all
      post :items_for_result
      post :resource_in_tab
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
      post :resource_in_tab
    end
    resources :people,:projects,:assays,:studies,:models,:sops,:data_files,:publications,:only=>[:index]
    resources :snapshots, :only => [:show, :new, :create, :destroy] do
      member do
        get :mint_doi_confirm
        post :mint_doi
        get :download
        get :export, to: :export_preview
        post :export, to: :export_submit
      end
    end
    member do
      get :new_object_based_on_existing_one
      post :check_related_items
      post :check_gatekeeper_required
      post :publish_related_items
      post :publish
      get :published
    end
  end

  resources :studies do
    collection do
      get :preview
      post :investigation_selected_ajax
      post :items_for_result
      post :resource_in_tab
    end
    resources :snapshots, :only => [:show, :new, :create, :destroy] do
      member do
        get :mint_doi_confirm
        post :mint_doi
        get :download
        get :export, to: :export_preview
        post :export, to: :export_submit
      end
    end
    member do
      get :new_object_based_on_existing_one
      post :check_related_items
      post :check_gatekeeper_required
      post :publish_related_items
      post :publish
      get :published
    end
    resources :people,:projects,:assays,:investigations,:models,:sops,:data_files,:publications,:only=>[:index]
  end

  resources :assays do
    collection do
      get :typeahead
      get :preview
      post :items_for_result
      #MERGENOTE - these should be gets and are tested as gets, using post to fix later
      post :resource_in_tab
    end
    resources :snapshots, :only => [:show, :new, :create, :destroy] do
      member do
        get :mint_doi_confirm
        post :mint_doi
        get :download
        get :export, to: :export_preview
        post :export, to: :export_submit
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
    end
    resources :people,:projects,:investigations,:samples, :studies,:models,:sops,:data_files,:publications,:strains,:only=>[:index]
  end


   ### ASSAY AND TECHNOLOGY TYPES ###

  resources :suggested_assay_types do
      collection do
        get :manage
      end

  end
  resources :suggested_modelling_analysis_types, :path => :suggested_assay_types, :controller => :suggested_assay_types do
     collection do
        get :manage
      end
  end
  resources :suggested_technology_types do
    collection do
      get :manage
    end
  end


  ### ASSETS ###

  resources :data_files do
    collection do
      get :typeahead
      get :preview
      get :filter
      post :test_asset_url
      post :upload_for_tool
      post :upload_from_email
      post :items_for_result
      post :resource_in_tab
    end
    member do
      get :matching_models
      get :data
      post :check_gatekeeper_required
      get :plot
      get :explore
      get :download
      get :published
      post :check_related_items
      post :publish_related_items
      post :publish
      post :request_resource
      post :convert_to_presentation
      post :update_annotations_ajax
      post :new_version
      #MERGENOTE - this is a destroy, and should be the destroy method, not post since we are not updating or creating something.
      post :destroy_version
      get :mint_doi_confirm
      get :minted_doi
      post :mint_doi
      get :samples_table
      get :select_sample_type
    end
    resources :studied_factors do
      collection do
        post :create_from_existing
      end
    end
    resources :content_blobs do
      member do
        get :view_pdf_content
        get :view_content
        get :get_pdf
        get :download
      end
    end
    resources :people,:projects,:investigations,:assays, :samples, :studies,:publications,:events,:only=>[:index]
  end

  resources :presentations do
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
      delete :destroy_version
    end
    resources :content_blobs do
      member do
        get :view_pdf_content
        get :view_content
        get :get_pdf
        get :download
      end
    end
    resources :people,:projects,:publications,:events,:only=>[:index]
  end

  resources :models do
    collection do
      get :typeahead
      get :preview
      post :test_asset_url
      post :items_for_result
      post :resource_in_tab
    end
    member do
      get :compare_versions
      post :compare_versions
      post :check_related_items
      get :visualise
      post :check_gatekeeper_required
      get :download
      get :matching_data
      get :published
      post :publish_related_items
      post :new_version
      post :submit_to_sycamore
      post :export_as_xgmml
      post :update_annotations_ajax
      post :publish
      post :execute
      post :request_resource
      post :simulate
      delete :destroy_version
      post :mint_doi
      get :mint_doi_confirm
    end
    resources :model_images do
      collection do
        post :new
      end
      member do
        post :select
      end
    end

    resources :content_blobs do
      member do
        get :view_pdf_content
        get :view_content
        get :get_pdf
        get :download
      end
    end
    resources :people,:projects,:investigations,:assays,:studies,:publications,:events,:only=>[:index]
  end

  resources :sops do
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
      delete :destroy_version
      post :mint_doi
      get :mint_doi_confirm
    end
    resources :experimental_conditions do
      collection do
        post :create_from_existing
      end
    end
    resources :content_blobs do
      member do
        get :view_pdf_content
        get :view_content
        get :get_pdf
        get :download
      end
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
      get :initiate_spawn_project
      get :activation_review
      put :accept_activation
      put :reject_activation
      get :reject_activation_confirmation
      post :spawn_project
      get :storage_report
    end
    resources :people,:projects, :institutions, :investigations, :studies, :assays,
              :data_files, :models, :sops, :presentations, :events, :publications
  end

  resources :publications do
    collection do
      get :typeahead
      get :preview
      post :fetch_preview
      post :items_for_result
      post :resource_in_tab
    end
    member do
      post :update_annotations_ajax
      post :disassociate_authors
    end
    resources :people,:projects,:investigations,:assays,:studies,:models,:data_files,:events,:only=>[:index]
  end

  resources :events do
    collection do
      get :typeahead
      get :preview
      post :items_for_result
      post :resource_in_tab
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
      post :resource_in_tab
    end
    member do
      post :update_annotations_ajax
    end
    resources :specimens,:assays,:people,:projects,:only=>[:index]
  end

  resources :organisms do
    collection do
      post :search_ajax
      post :resource_in_tab
    end
    resources :projects,:assays,:studies,:models,:strains,:specimens,:only=>[:index]
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

  resources :workflows do
    collection do
      get :typeahead
      post :test_asset_url
    end

    member do
      get :download
      get :describe_ports
      post :temp_link
      post :new_version
      post :update_annotations_ajax
      post :check_related_items
      post :publish
      get :published
      post :favourite
      delete :favourite_delete
      post :mint_doi
      get :mint_doi_confirm
    end

    resources :runs, :controller => 'taverna_player/runs'
  end

  resources :runs, :controller => 'taverna_player/runs', :only => ['edit', 'update'] do
    member do
      post :report_problem
    end
  end

  resources :group_memberships

  resources :sweeps do
    member do
      put :cancel
      get :runs
      post :download_results
      get :view_result
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
      post :extract_from_data_file
    end
    member do
      post :update_annotations_ajax
    end
  end

  ### ASSAY AND TECHNOLOGY TYPES ###

  get '/assay_types/',:to=>"assay_types#show",:as=>"assay_types"
  get '/modelling_analysis_types/',:to=>"assay_types#show",:as=>"modelling_analysis_types"
  get '/technology_types/',:to=>"technology_types#show",:as=>"technology_types"


  resources :statistics, :only => [:index]
  ### MISC MATCHES ###
  match '/search/' => 'search#index', :as => :search
  match '/search/save' => 'search#save', :as => :save_search
  match '/search/delete' => 'search#delete', :as => :delete_search
  match '/search/items_for_result' => 'search#items_for_result', :via => :post
  match 'svg/:id.:format' => 'svg#show', :as => :svg
  match '/tags/latest' => 'tags#latest', :as => :latest_tags
  match '/tags/query' => 'tags#query', :as => :query_tags
  match '/tags' => 'tags#index', :as => :all_tags
  match '/tags/:id' => 'tags#show', :as => :show_tag
  match '/tags' => 'tags#index', :as => :all_anns
  match '/tags/:id' => 'tags#show', :as => :show_ann
  match '/jerm/' => 'jerm#index', :as => :jerm
  match '/jerm/fetch' => 'jerm#fetch', :as=>:jerm
  match '/countries/:country_name' => 'countries#show', :as => :country

  match '/data_fuse/' => 'data_fuse#show', :as => :data_fuse
  match '/favourite_groups/new' => 'favourite_groups#new', :as => :new_favourite_group, :via => :post
  match '/favourite_groups/create' => 'favourite_groups#create', :as => :create_favourite_group, :via => :post
  match '/favourite_groups/edit' => 'favourite_groups#edit', :as => :edit_favourite_group, :via => :post
  match '/favourite_groups/update' => 'favourite_groups#update', :as => :update_favourite_group, :via => :post
  match '/favourite_groups/:id' => 'favourite_groups#destroy', :as => :delete_favourite_group, :via => :delete
  match 'studies/new_investigation_redbox' => 'studies#new_investigation_redbox', :as => :new_investigation_redbox, :via => :post
  match 'experiments/create_investigation' => 'studies#create_investigation', :as => :create_investigation, :via => :post
  match '/work_groups/review/:type/:id/:access_type' => 'work_groups#review_popup', :as => :review_work_group, :via => :post
  match ':controller/:id/approve_or_reject_publish' => ":controller#show"

  match '/signup' => 'users#new', :as => :signup

  match '/logout' => 'sessions#destroy', :as => :logout
  match '/login' => 'sessions#new', :as => :login
  match '/activate/:activation_code' => 'users#activate', :activation_code => nil, :as => :activate
  match '/forgot_password' => 'users#forgot_password', :as => :forgot_password
  match '/policies/request_settings' => 'policies#send_policy_data', :as => :request_policy_settings
  match '/fail'=>'fail#index',:as=>:fail,:via=>:get

  #feedback
  match '/home/feedback' => 'homes#feedback', :as=> :feedback, :via=>:get

  #tabber lazy load
  match 'application/resource_in_tab' => 'application#resource_in_tab'

  #error rendering
  match "/404" => "errors#error_404"
  match "/422" => "errors#error_422"
  match "/500" => "errors#error_500"

  match "/zenodo_oauth_callback" => "zenodo/oauth2/callbacks#callback"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
