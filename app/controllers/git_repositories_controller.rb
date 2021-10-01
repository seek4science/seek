class GitRepositoriesController < ApplicationController
  before_action :get_repository

  def status
    status = @git_repository.remote_git_fetch_task&.status

    respond_to do |format|
      format.json { render json: { status: status, text: status.to_s.humanize } }
    end
  end

  def refs
    respond_to do |format|
      format.json { render json: @git_repository.remote_refs.to_json }
    end
  end

  private

  def get_repository
    @git_repository = Git::Repository.find(params[:id])
  end

end
