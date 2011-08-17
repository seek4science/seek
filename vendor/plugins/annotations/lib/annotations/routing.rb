module Annotations #:nodoc:
  def self.map_routes(map, collection={}, member={})
    map.resources :annotations,
                  :collection => { :create_multiple => :post }.merge(collection),
                  :member => {}.merge(member)
  end
end
