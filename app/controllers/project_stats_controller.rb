class ProjectStatsController < StatsController
  before_action :member_of_this_project
  skip_before_action :is_user_admin_auth

  private

  def stats
    Seek::Stats::ProjectDashboardStats.new(@project)
  end

  def get_scope
    name = t('project')
    @scope = @project = Project.find_by_id(params[:project_id])
    if @project.nil?
      respond_to do |format|
        flash[:error] = "The #{name.humanize} does not exist!"
        format.html { redirect_to project_path(@project) }
      end
    end
  end

  def member_of_this_project
    unless @project.has_member?(current_user)
      flash[:error] = "You are not a member of this #{t('project')}, so cannot access this page."
      redirect_to project_path(@project)
      false
    end
  end
end
