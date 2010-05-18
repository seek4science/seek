ActionController::Routing::Routes.draw do |map|

  map.resources :site_announcements,:collection=>{:feed=>:get,:notification_settings=>:get}
  
end