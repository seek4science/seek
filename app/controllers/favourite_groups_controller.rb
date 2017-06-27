class FavouriteGroupsController < ApplicationController
  include WhiteListHelper

  before_filter :login_required
  before_filter :find_favourite_group, only: %i[edit update destroy]
  before_filter :set_no_layout, only: %i[new edit]

  protect_from_forgery except: %i[create update destroy]

  skip_before_filter :project_membership_required

  def new
    @f_group = FavouriteGroup.new

    respond_to do |format|
      format.js # new_popup.html.erb
    end
  end

  def create
    group_name = white_list(params[:favourite_group_name])
    already_exists = FavouriteGroup.where(name: group_name, user_id: current_user.id).first

    if already_exists
      # group with such name already existed for current user => error
      created = false
    else
      # group doesn't exist - create a new one..
      new_group = FavouriteGroup.create(name: group_name, user_id: current_user.id)
      created = new_group.save

      if created
        # ..and add all members to it
        group_members = ActiveSupport::JSON.decode(white_list(params[:favourite_group_members]))
        group_members.each do |memb|
          person_id = memb[0].to_i
          person_access_type = memb[1]
          FavouriteGroupMembership.create(person_id: person_id, access_type: person_access_type, favourite_group_id: new_group.id)
        end

        # ..also while results of this are being sent back, send the updated favourite group list for current user
        users_favourite_groups = FavouriteGroup.get_all_without_blacklists_and_whitelists(current_user.id)
      end
    end

    respond_to do |format|
      format.json do
        if created
          render json: { status: 200, group_class_name: new_group.class.name, group_name: new_group.name, group_id: new_group.id, favourite_groups: users_favourite_groups }
        elsif already_exists
          render json: { status: 422, error_message: "You already have a #{t('favourite_group')} with such name.\nPlease change it and try again." }
        else
          render json: { status: 500, error_message: "Couldn't create #{t('favourite_group')}." }
        end
      end
    end
  end

  def edit
    respond_to do |format|
      format.js # edit_popup.html.erb
    end
  end

  def update
    group_name = white_list(params[:favourite_group_name])
    found = FavouriteGroup.where(name: group_name, user_id: current_user.id).first

    # if the found group with the same is the current one - that's fine; otherwise - can't rename a group with such new name
    already_exists = if found.nil?
                       false
                     else
                       (found.id != @f_group.id)
                     end

    unless already_exists
      # SYNCHRONIZE GROUP MEMBERS
      changes_made = false
      group_members = ActiveSupport::JSON.decode(white_list(params[:favourite_group_members]))

      # first delete any old memberships that are no longer valid
      @f_group.favourite_group_memberships.each do |memb|
        unless group_members[memb.person_id.to_s]
          memb.destroy
          changes_made = true
        end
      end
      # this is required to leave the association of @f_group with its memberships in the correct state; otherwise exception is thrown
      @f_group.reload if changes_made

      # update the remaining old memberships if the access type has changed for them
      @f_group.favourite_group_memberships.each do |memb|
        next if memb.access_type == group_members[memb.person_id.to_s]
        memb.access_type = group_members[memb.person_id.to_s]
        memb.save!
        changes_made = true
      end

      # now add any remaining new memberships
      group_members.each do |new_memb|
        person_id = new_memb[0].to_i
        person_access_type = new_memb[1]
        unless (found = FavouriteGroupMembership.where(person_id: person_id, favourite_group_id: @f_group.id).first)
          FavouriteGroupMembership.create(person_id: person_id, access_type: person_access_type, favourite_group_id: @f_group.id)
          changes_made = true
        end
      end

      # UPDATE THE GROUP
      unless @f_group.name == group_name
        @f_group.name = group_name
        changes_made = true
      end

      # CHECK IF THE MAIN GROUP RECORD NEEDS TO BE RESAVED
      @f_group.save if changes_made

      # ..also while results of this are being sent back, send the updated favourite group list for current user
      users_favourite_groups = FavouriteGroup.get_all_without_blacklists_and_whitelists(current_user.id)
    end

    respond_to do |format|
      format.json do
        if already_exists # already_exists
          render json: { status: 422, error_message: "You already have a #{t('favourite_group')} with such name.\nPlease change it and try again." }
        else
          render json: { status: 200, group_class_name: @f_group.class.name, group_name: @f_group.name, group_id: @f_group.id, favourite_groups: users_favourite_groups }
        end
      end
    end
  end

  def destroy
    # these parameters will be needed for the client-side processing
    class_name = @f_group.class.name
    group_name = @f_group.name
    group_id = @f_group.id
    @f_group.destroy

    # ..also while results of this are being sent back, send the updated favourite group list for current user
    users_favourite_groups = FavouriteGroup.get_all_without_blacklists_and_whitelists(current_user.id)

    respond_to do |format|
      format.json do
        render json: { status: 200, group_class_name: class_name, group_name: group_name, group_id: group_id, favourite_groups: users_favourite_groups }
      end
    end
  end

  private

  def find_favourite_group
    f_group = FavouriteGroup.where(user_id: current_user.id).find(params[:id])

    if f_group
      @f_group = f_group
    else
      respond_to do |format|
        flash[:error] = 'You are not authorized to perform this action'
        format.html { redirect_to person_path(current_person) }
      end
      return false
    end
  end
end
