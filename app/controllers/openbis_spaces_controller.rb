class OpenbisSpacesController < ApplicationController

  before_filter :get_project
  before_filter :project_required
  before_filter :project_can_admin?


  def project_required
    return false unless @project
  end

  def get_project
    @project=Project.find(params[:project_id])
  end

  def project_can_admin?
    unless @project.can_be_administered_by?(current_user)
      error("Insufficient privileges", "is invalid (insufficient_privileges)")
      return false
    end
  end

end