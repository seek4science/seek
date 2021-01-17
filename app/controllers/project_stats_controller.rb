class ProjectStatsController < StatsController
  skip_before_action :is_user_admin_auth
  prepend_before_action :find_and_authorize_project

  private

  def stats
    Seek::Stats::DashboardStats.new(@project)
  end

  def find_and_authorize_project
    name = t('project')
    @project = Project.find_by_id(params[:project_id])
    if @project.nil?
      respond_to do |format|
        flash[:error] = "The #{name.humanize} does not exist!"
        format.html { redirect_to project_path(@project) }
      end
      return false
    end

    unless @project.has_member?(current_user)
      flash[:error] = "You are not a member of this #{name}, so cannot access this page."
      redirect_to project_path(@project)
      return false
    end

    true
  end
end
