module Seek
  module ResourceRelatedTabs
    def view_items_in_tab
        resource_type = params[:resource_type]
        resource_ids = params[:resource_ids].split(',')
        resources = resource_type.constantize.find(:all, :conditions => ['id IN (?)', resource_ids])
        render :update do |page|
          page.replace_html "#{resource_type}_list_items_container", :partial => "assets/resource_list", :locals => {:collection => resources, :narrow_view => true, :authorization_for_showing_already_done => true}
          page.visual_effect :toggle_blind, "view_#{resource_type}s", :duration => 0.05
          page.visual_effect :toggle_blind, "view_#{resource_type}s_and_extra", :duration => 0.05
        end
    end
  end
end