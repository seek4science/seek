class CitationsController < ApplicationController
  before_action :set_citation_style

  def fetch
    respond_to do |format|
      format.js { render partial: 'assets/citation', locals: { doi: params[:doi], style: params[:style] } }
    end
  end

  private

  def set_citation_style
    session[:citation_style] = params[:style] if params[:style].present?
  end
end
