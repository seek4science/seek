class InvestigationsController < ApplicationController

  before_filter :login_required

  def show
    @investigation=Investigation.find(params[:id])

    respond_to do |format|
      format.html
      format.xml { render :xml=> @investigation, :include=>@investigation.studies }
    end

  end
end
