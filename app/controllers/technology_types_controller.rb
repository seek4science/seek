class TechnologyTypesController < ApplicationController

  before_filter :login_required

  def show
    @technology_type = TechnologyType.find(params[:id])

    respond_to do |format|
      format.html
      format.xml { render :xml=>@technology_type}
    end

  end

end
