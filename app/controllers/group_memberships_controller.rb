class GroupMembershipsController < ApplicationController

  def destroy
    @group_membership = GroupMembership.find(params[:id])
    membership_to = "the #{@group_membership.work_group.project.title} project as a member of #{@group_membership.work_group.institution.title}"
    respond_to do |format|
      if (@group_membership.person.user == current_user || current_user.is_admin?) && @group_membership.destroy
        flash[:notice] = "This person has been removed from #{membership_to} workgroup"
      else
        flash[:error] = "Could not remove person from #{membership_to}"
      end
      format.html { redirect_back fallback_location: root_path }
    end
  end

end