class PreviewsController < ApplicationController
  before_action :login_required

  def markdown
    @markdown = params[:content]
    respond_to do |format|
      format.html { render partial: 'previews/markdown' }
    end
  end
end
