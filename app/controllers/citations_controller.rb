class CitationsController < ApplicationController

  def fetch
    respond_to do |format|
      format.js { render partial: 'assets/citation', locals: { doi: params[:doi], style: params[:style] } }
    end
  end

end
