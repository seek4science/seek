ActionController::Routing::Routes.draw do |map|
  map.resources :sops, :member => { :download => :get }

  map.resources :assets

  map.resources :users, :collection=>{:activation_required=>:get}

  map.resource :session

  #map.resources :profiles

  map.resources :institutions, 
    :collection => { :request_all => :get } do |institution|
    # avatars / pictures 'owned by' institution
    institution.resources :avatars, :member => { :select => :post }
  end

  map.resources :groups

  map.resources :projects, 
    :collection => { :request_institutions => :get } do |project|
    # avatars / pictures 'owned by' project
    project.resources :avatars, :member => { :select => :post }
  end

  map.resources :people, :collection=>{:select=>:get} do |person|
    # avatars / pictures 'owned by' person
    person.resources :avatars, :member => { :select => :post }
  end
  
  map.resources :expertise
  
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
  
  # used by the "sharing" form to get settings from an existing policy 
  map.request_policy_settings '/policies/request_settings', :controller => 'policies', :action => 'send_policy_data'
  
  # routes for favourite
  map.new_favourite_group '/favourite_groups/new_popup', :controller => 'favourite_groups', :action => 'new_popup', :conditions => { :method => :post }
  map.edit_favourite_group '/favourite_groups/:id/edit_popup', :controller => 'favourite_groups', :action => 'edit_popup', :conditions => { :method => :post }
  
  map.root :controller=>"home"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
