class CitationsController < ApplicationController
  before_action :set_citation_style
  skip_forgery_protection only:[:fetch]

  def fetch
    respond_to do |format|
      format.js { render partial: 'assets/citation_from_doi', locals: { doi: params[:doi], style: params[:style] } }
    end
  end

  private

  def set_citation_style
    session[:citation_style] = params[:style] if params[:style].present?
  end
end
