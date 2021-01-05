class GitRepositoriesController < ApplicationController
  before_action :get_repository, only: :show

  def show
    respond_to do |format|
      format.html
    end
  end

  def create
    respond_to do |format|
      format.html
    end
  end

  def fetching_status
    @previous_status = params[:previous_status]
    @job_status = @git_repository.fetching_status

    respond_to do |format|
      format.html { render partial: 'git_repositories/fetching_status', locals: { git_repository: @git_repository } }
    end
  end

  private

  def get_repository
    @git_repository = GitRepository.find(params[:id])
  end

end
