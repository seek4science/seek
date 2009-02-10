require 'white_list_helper'

class FavouriteGroupsController < ApplicationController
  include WhiteListHelper
  
  before_filter :login_required
  before_filter :find_favourite_group, :only => [ :edit ]
  before_filter :set_no_layout, :only => [ :new, :edit ]
  
  protect_from_forgery :except => [:create, :update, :delete]
  
  
  def new
    @f_group = FavouriteGroup.new
    
    respond_to do |format|
      format.js # new_popup.html.erb
    end
  end
  
  def create
    group_name = white_list(params[:favourite_group_name])
    already_exists = FavouriteGroup.find(:first, :conditions => { :name => group_name, :user_id => current_user.id })
    
    unless already_exists
      # group doesn't exist - create a new one..
      new_group = FavouriteGroup.create( :name => group_name, :user_id => current_user.id )
      created = new_group.save
      
      if created
        # ..and add all members to it
        group_members = ActiveSupport::JSON.decode(white_list(params[:favourite_group_members]))
        group_members.each do |memb|
          person_id = memb[0].to_i
          person_access_type = memb[1]
          FavouriteGroupMembership.create(:person_id => person_id, :access_type => person_access_type, :favourite_group_id => new_group.id)
        end
        
        # ..also while results of this are being sent back, send the updated favourite group list for current user
        users_favourite_groups = FavouriteGroup.get_all_without_blacklists_and_whitelists(current_user.id)
      end
    else
      # group with such name already existed for current user => error
      created = false
    end
    
    respond_to do |format|
      format.json {
        if created
          render :json => {:status => 200, :group_class_name => new_group.class.name, :group_name => new_group.name, :group_id => new_group.id, :favourite_groups => users_favourite_groups }
        elsif already_exists
          render :json => {:status => 403, :error_message => "You already have a favourite group with such name." }
        else
          render :json => {:status => 500, :error_message => "Couldn't create favourite group." }
        end
      }
    end
  end
  
  def edit
    respond_to do |format|
      format.js # edit_popup.html.erb
    end
  end
  
  
  private
  
  def find_favourite_group
    f_group = FavouriteGroup.find(params[:id], :conditions => { :user_id => current_user.id } )
    
    if f_group
      @f_group = f_group
      puts "================="
      puts @f_group.name
    else
      respond_to do |format|
        flash[:error] = "You are not authorized to perform this action"
        format.html { redirect_to person_path(current_user.person) }
      end
      return false
    end
  end
  
end
