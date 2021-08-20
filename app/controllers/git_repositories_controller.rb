class GitRepositoriesController < ApplicationController
  before_action :get_repository, only: [:show, :select_ref, :fetch_status]

  def show
    respond_to do |format|
      format.html
    end
  end

  def create
    @git_repository = Git::Repository.find_or_create_by(remote: params[:remote])
    @git_repository.queue_fetch

    respond_to do |format|
      format.html { redirect_to select_ref_git_repository_path(@git_repository, resource_type: params[:resource_type]) }
    end
  end

  def fetch_status
    status = @git_repository.remote_git_fetch_task&.status

    respond_to do |format|
      format.json { render json: { status: status, text: status.to_s.humanize } }
    end
  end

  def select_ref

  end

  private

  def get_repository
    @git_repository = Git::Repository.find(params[:id])
  end

end
