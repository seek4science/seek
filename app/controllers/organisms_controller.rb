class OrganismsController < ApplicationController

  before_filter :login_required
  before_filter :find_organism,:only=>[:show]

  def show
    respond_to do |format|
      format.html
      format.xml {render :xml=>@organism}
    end
  end

  private

  def find_organism
    begin
      @organism=Organism.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "The Organism selected does not exist"
        format.html { redirect_to root_path }
      end    
    end
  end
  
end
