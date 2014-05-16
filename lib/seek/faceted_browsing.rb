module Seek

  module FacetedBrowsing

    def faceted_items
      item_type = params[:item_type]
      item_ids = (params[:item_ids] || []).collect(&:to_i)

      resources = []
      if !item_type.blank?
        clazz = item_type.constantize
        resources = clazz.find_all_by_id(item_ids)
        if clazz.respond_to?(:authorize_asset_collection)
          resources = clazz.authorize_asset_collection(resources,"view")
        else
          resources = resources.select &:can_view?
        end
      end

      resources.sort!{|a,b| item_ids.index(a.id) <=> item_ids.index(b.id)}
      resource_list_items = resources.collect{|resource| render_to_string :partial => "assets/resource_list_item", :object => resource}

      respond_to do |format|
        format.json {render :json => {:resource_list_items => resource_list_items.join(' ')}}
      end
    end

    def ie_support_faceted_browsing?
      @ie_support_faceted_browsing = true
      user_agent = request.env["HTTP_USER_AGENT"]
      index = user_agent.try(:index, 'MSIE')
      if !index.nil?
        version = user_agent[(index+5)..(index+8)].to_i
        if version != 0 && version < 9
          @ie_support_faceted_browsing = false
        end
      end
      @ie_support_faceted_browsing
    end

  end
end
