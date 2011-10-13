module Annotations #:nodoc:
  def self.map_routes(map, collection={}, member={}, requirements={})
    map.resources :annotations,
                  :collection => { :create_multiple => :post }.merge(collection),
                  :member => {}.merge(member),
                  :requirements => { }.merge(requirements)
  end
end
