class FavouriteGroupsController < ApplicationController
  before_filter :login_required
  before_filter :find_favourite_group, :only => [ :edit_popup ]
  before_filter :set_no_layout, :only => [ :new_popup, :edit_popup ]
  
  def new_popup
    @f_group = FavouriteGroup.new
    
    respond_to do |format|
      format.js # new_popup.html.erb
    end
  end
  
  def edit_popup
    respond_to do |format|
      format.js # edit_popup.html.erb
    end
  end
  
  private
  
  def find_favourite_group
    # TODO replace with a proper "find"
    @f_group = FavouriteGroup.new
  end
  
end
