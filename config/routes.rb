SEEK::Application.routes.draw do
  root :to=>"home#index"

  resource :admin do
    member do
      get :show
      get :tags
      get :features_enabled
      get :rebrand
      get :home_settings
      get :pagination
      get :biosamples_renaming
      get :others
      get :get_stats
      get :registration_form
      get :restart_server
      get :update_home_settings
      post :get_stats
      post :update_admins
      post :update_rebrand
      post :test_email_configuration
      post :update_others
      post :update_features_enabled
      post :update_pagination
    end
  end

  resources :attachments
  resources :presentations do

    member do
      get :check_related_items
      get :check_gatekeeper_required
      post :publish
      post :request_resource
      get :download
      post :update_annotations_ajax
      get :published
      get :approve_or_reject_publish
      get :publish_related_items
      post :gatekeeper_decide
      post :new_version
    end
    resources :content_blobs do

      member do
        get :view_pdf_content
        get :get_pdf
        get :download
      end

    end
  end

  resources :subscriptions
  resources :specimens
  resources :samples
  resources :events
  resources :strains do

    member do
      post :update_annotations_ajax
    end

  end

  resources :publications do
    collection do
      post :fetch_preview
    end
    member do
      post :update_annotations_ajax
      post :disassociate_authors
    end

  end

  resources :assay_types do
    collection do
      get :manage
    end


  end

  resources :organisms do

    member do
      get :visualise
    end

  end

  resources :technology_types do
    collection do
      get :manage
    end


  end

  resources :measured_items
  resources :investigations do

    member do
      get :approve_or_reject_publish
      post :gatekeeper_decide
    end

  end

  resources :studies do

    member do
      get :approve_or_reject_publish
      post :gatekeeper_decide
    end

  end

  resources :assays do

    member do
      post :update_annotations_ajax
      get :approve_or_reject_publish
      post :gatekeeper_decide
    end

  end

  resources :saved_searches
  resources :biosamples do
    collection do
      put :update_strain
      get :existing_strains
      post :create_specimen_sample
      get :existing_specimens
      get :strains_of_selected_organism
      get :existing_samples
      get :strain_form
      post :create_strain
    end


  end

  resources :data_files do
    collection do
      post :test_asset_url
    end
    member do
      get :check_related_items
      get :matching_models
      get :data
      get :check_gatekeeper_required
      post :publish
      get :plot
      get :explore
      post :request_resource
      get :download
      post :convert_to_presentation
      post :update_annotations_ajax
      get :published
      get :approve_or_reject_publish
      get :publish_related_items
      post :gatekeeper_decide
    end
    resources :studied_factors do
      collection do
        post :create_from_existing
      end


    end

    resources :content_blobs do

      member do
        get :view_pdf_content
        get :get_pdf
        get :download
      end

    end
  end

  resources :spreadsheet_annotations, :only => [:create, :destroy, :update]
  resources :uuids
  resources :institutions do
    collection do
      get :request_all
    end

    resources :avatars do
      member do
        post :select
      end

    end
  end

  resources :models do
    collection do
      get :build
    end
    member do
      get :builder
      get :check_related_items
      get :visualise
      get :check_gatekeeper_required
      post :publish
      post :execute
      post :request_resource
      get :download
      post :update_annotations_ajax
      post :simulate
      get :matching_data
      get :published
      post :export_as_xgmml
      get :approve_or_reject_publish
      get :publish_related_items
      post :submit_to_jws
      post :gatekeeper_decide
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
        get :get_pdf
        get :download
      end

    end
  end

  resources :people do
    collection do
      get :select
      get :get_work_group
    end
    member do
      get :check_related_items
      get :check_gatekeeper_required
      post :publish
      get :admins
      get :published
      get :batch_publishing_preview
      get :publish_related_items
    end
    resources :avatars do
      member do
        post :select
      end

    end
  end

  resources :projects do
    collection do
      get :request_institutions
    end
    member do
      get :asset_report
      get :admins
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
        post :display_contents
        post :move_asset_to
        post :create_folder
      end

    end
  end

  resources :sops do

    member do
      get :check_related_items
      get :check_gatekeeper_required
      post :publish
      post :request_resource
      get :download
      post :update_annotations_ajax
      get :published
      get :approve_or_reject_publish
      get :publish_related_items
      post :gatekeeper_decide
      post :new_version
    end
    resources :experimental_conditions do
      collection do
        post :create_from_existing
      end


    end

    resources :content_blobs do

      member do
        get :view_pdf_content
        get :get_pdf
        get :download
      end

    end
  end

  resources :users do
    collection do
      get :activation_required
      get :forgot_password
      post :forgot_password
      get :reset_password
      post :hide_guide_box
      post :impersonate
    end
    member do
      put :set_openid
    end

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

  resource :favourites do
    collection do
      post :add
    end
    member do
      delete :delete
    end

  end

  resources :help_documents do


    resources :help_attachments, :only => [:create, :destroy] do

      member do
        get :download
      end

    end

    resources :help_images, :only => [:create, :destroy]
  end

  resources :forum_attachments, :only => [:create, :destroy] do

    member do
      get :download
    end

  end

  resources :compounds
  match '/search/' => 'search#index', :as => :search
  match '/search/save' => 'search#save', :as => :save_search
  match '/search/delete' => 'search#delete', :as => :delete_search
  match 'svg/:id.:format' => 'svg#show', :as => :svg
  match '/tags' => 'tags#index', :as => :all_tags
  match '/tags/:id' => 'tags#show', :as => :show_tag
  match '/tags' => 'tags#index', :as => :all_anns
  match '/tags/:id' => 'tags#show', :as => :show_ann
  match '/jerm/' => 'jerm#index', :as => :jerm
  match '/countries/:country_name' => 'countries#show', :as => :country

  match '/data_fuse/' => 'data_fuse#show', :as => :data_fuse
  match '/home/feedback' => 'home#feedback', :as => :feedback, :method => :get
  match '/home/send_feedback' => 'home#send_feedback', :as => :send_feedback, :method => :post
  match 'home/seek_intro_demo' => 'home#seek_intro_demo', :as => :seek_intro_demo, :method => :get
  match '/favourite_groups/new' => 'favourite_groups#new', :as => :new_favourite_group, :via => :post
  match '/favourite_groups/create' => 'favourite_groups#create', :as => :create_favourite_group, :via => :post
  match '/favourite_groups/edit' => 'favourite_groups#edit', :as => :edit_favourite_group, :via => :post
  match '/favourite_groups/update' => 'favourite_groups#update', :as => :update_favourite_group, :via => :post
  match '/favourite_groups/:id' => 'favourite_groups#destroy', :as => :delete_favourite_group, :via => :delete
  match 'studies/new_investigation_redbox' => 'studies#new_investigation_redbox', :as => :new_investigation_redbox, :via => :post
  match 'experiments/create_investigation' => 'studies#create_investigation', :as => :create_investigation, :via => :post
  match '/work_groups/review/:type/:id/:access_type' => 'work_groups#review_popup', :as => :review_work_group, :via => :post
  match ':controller/new_object_based_on_existing_one/:id' => "#new_object_based_on_existing_one", :as => :new_object_based_on_existing_one, :via => :post
  match '/tool_list_autocomplete' => 'people#auto_complete_for_tools_name', :as => :tool_list_autocomplete
  match '/expertise_list_autocomplete' => 'people#auto_complete_for_expertise_name', :as => :expertise_list_autocomplete
  match '/organism_list_autocomplete' => 'projects#auto_complete_for_organism_name', :as => :organism_list_autocomplete
  match '/' => 'home#index'
  match 'index.html' => 'home#index', :as => :match
  match 'index' => 'home#index', :as => :match
  match '/signup' => 'users#new', :as => :signup
  match '/login' => 'home#index', :as => :login
  match '/logout' => 'sessions#destroy', :as => :logout
  match '/activate/:activation_code' => 'users#activate', :activation_code => nil, :as => :activate
  match '/forgot_password' => 'users#forgot_password', :as => :forgot_password
  match '/policies/request_settings' => 'policies#send_policy_data', :as => :request_policy_settings

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
