class DashboardsController < ApplicationController
  before_filter :find_project
  before_filter :member_of_this_project
  before_filter :expire_fragment_check, except: :show

  include Seek::BreadCrumbs

  def show

  end

  def stats
    render partial: "dashboards/#{params[:query]}"
  end

  def contributions
    @start_date = Date.parse(params[:start_date])
    @end_date = Date.parse(params[:end_date])
    @interval = params[:interval] || 'months'

    respond_to do |format|
      format.json
    end
  end

  private

  def find_project
    name = t('project')
    @project = Project.find_by_id(params[:project_id])
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

  def expire_fragment_check
    expire_fragment("project_dashboard_#{@project.id}_#{action_name}") if params[:refresh]
  end
end
