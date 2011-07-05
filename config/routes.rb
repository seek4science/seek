ActionController::Routing::Routes.draw do |map|
  map.resources :subscriptions
  map.resources :specimens
  map.resources :samples

  map.resources :events
  map.resources :tissue_and_cell_types
  map.resources :strains

  map.resources :publications,:collection=>{:fetch_preview=>:post},:member=>{:disassociate_authors=>:post,:update_tags_ajax=>:post}

  map.resources :assay_types, :collection=>{:manage=>:get}

  map.resources :organisms, :member=>{:visualise=>:get}

  map.resources :technology_types, :collection=>{:manage=>:get}

  map.resources :measured_items

  map.resources :investigations

  map.resources :studies

  map.resources :assays,:member=>{:update_tags_ajax=>:post}

  map.resources :saved_searches

  map.resources :data_files, :collection=>{:test_asset_url=>:post},:member => {:download => :get,:plot=>:get, :data => :get,:preview_publish=>:get,:publish=>:post, :request_resource=>:post, :update_tags_ajax=>:post},:new=>{:upload_for_tool => :post}  do |data_file|
    data_file.resources :studied_factors
  end
  
  map.resources :uuids

  map.resources :institutions,
    :collection => { :request_all => :get } do |institution|
    # avatars / pictures 'owned by' institution
    institution.resources :avatars, :member => { :select => :post }, :collection => { :new => :post }
  end

  map.resources :models, 
    :member => { :download => :get, :execute=>:post, :request_resource=>:post,:preview_publish=>:get,:publish=>:post, :builder=>:get, :submit_to_jws=>:post, :simulate=>:post, :update_tags_ajax=>:post },
    :collection=>{:build=>:get}

  map.resources :people, :collection=>{:select=>:get,:get_work_group =>:get} do |person|
    # avatars / pictures 'owned by' person
    person.resources :avatars, :member => { :select => :post }, :collection => { :new => :post }
  end

  map.resources :projects,
    :collection => { :request_institutions => :get },:member=>{:admin=>:get} do |project|
    # avatars / pictures 'owned by' project
    project.resources :avatars, :member => { :select => :post }, :collection => { :new => :post }
  end

  map.resources :sops, :member => { :download => :get, :new_version=>:post, :preview_publish=>:get,:publish=>:post,:request_resource=>:post, :update_tags_ajax=>:post } do |sop|
    sop.resources :experimental_conditions
  end



  map.resources :users, :collection=>{:impersonate => :post, :activation_required=>:get,:forgot_password=>[:get,:post],:reset_password=>:get},
                        :member => {:set_openid => :put}

  map.resource :session, :collection=>{:auto_openid=>:get,:show=>:get,:index=>:get},:member=>{:show=>:get}
  
  #help pages
  map.resources :help_documents, :as => :help do |h|
    h.resources :help_attachments, :as => :attachments, :member => {:download => :get}, :only => [:create, :destroy]
    h.resources :help_images, :as => :images, :only => [:create, :destroy]
  end
  
  #forum attachments
  map.resources :forum_attachments, :member => {:download => :get}, :only => [:create, :destroy]
  
  # search and saved searches
  map.search '/search/',:controller=>'search',:action=>'index'
  map.save_search '/search/save',:controller=>'search',:action=>'save'
  map.delete_search '/search/delete',:controller=>'search',:action=>'delete'
  #map.saved_search '/search/:id',:controller=>'search',:action=>'show'

  map.svg 'svg/:id.:format',:controller=>'svg',:action=>'show'

  #tags
  map.all_tags '/tags',:controller=>'tags',:action=>'index'
  map.show_tag '/tags/:id',:controller=>'tags',:action=>'show'
  
  map.jerm '/jerm/',:controller=>'jerm',:action=>'index'
  
  # browsing by countries
  map.country '/countries/:country_name', :controller => 'countries', :action => 'show'

  # page for admin tasks
  map.admin '/admin/', :controller=>'admin',:action=>'show'

  #temporary location for the data/models simulation prototyping
  map.data_fuse '/data_fuse/',:controller=>'data_fuse',:action=>'show'

  #feedback form
  map.feedback '/home/feedback',:controller=>'home',:action=>'feedback',:method=>:get
  map.send_feedback '/home/send_feedback',:controller=>'home',:action=>'send_feedback',:method=>:post

  # favourite groups
  map.new_favourite_group '/favourite_groups/new', :controller => 'favourite_groups', :action => 'new', :conditions => { :method => :post }
  map.create_favourite_group '/favourite_groups/create', :controller => 'favourite_groups', :action => 'create', :conditions => { :method => :post }
  map.edit_favourite_group '/favourite_groups/edit', :controller => 'favourite_groups', :action => 'edit', :conditions => { :method => :post }
  map.update_favourite_group '/favourite_groups/update', :controller => 'favourite_groups', :action => 'update', :conditions => { :method => :post }
  map.delete_favourite_group '/favourite_groups/:id', :controller => 'favourite_groups', :action => 'destroy', :conditions => { :method => :delete }

  map.new_investigation_redbox 'studies/new_investigation_redbox',:controller=>"studies",:action=>'new_investigation_redbox',:conditions=> {:method=>:post}
  map.create_investigation 'experiments/create_investigation',:controller=>"studies",:action=>'create_investigation',:conditions=> {:method=>:post}
  
  
  # review members of workgroup (also of a project / institution) popup
  map.review_work_group '/work_groups/review/:type/:id/:access_type', :controller => 'work_groups', :action => 'review_popup', :conditions => { :method => :post }  
  
  #create new specimen based existing one
  #map.new_specimen_based_on_existing_one '/specimens/new_specimen_based_on_existing_one/:id',:controller=>'specimens',:action=>'new_specimen_based_on_existing_one', :conditions => { :method => :post }
  map.new_object_based_on_existing_one ':controller_name/new_object_based_on_existing_one/:id',:controller=>'#{controller_name}',:action=>'new_object_based_on_existing_one', :conditions => { :method => :post }


  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"
  
  #

  map.tool_list_autocomplete '/tool_list_autocomplete', :controller=>'people', :action=>'auto_complete_for_tools_name'
  map.expertise_list_autocomplete '/expertise_list_autocomplete', :controller=>'people', :action=>'auto_complete_for_expertise_name'
  map.organism_list_autocomplete '/organism_list_autocomplete',:controller=>'projects',:action=>'auto_complete_for_organism_name'
  
  map.signup  '/signup', :controller => 'users',   :action => 'new' 
  map.login  '/login',  :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'  
  
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil
  map.forgot_password '/forgot_password',:controller=>'users',:action=>'forgot_password'
  
  # used by the "sharing" form to get settings from an existing policy 
  map.request_policy_settings '/policies/request_settings', :controller => 'policies', :action => 'send_policy_data'

  map.root :controller=>"home"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
