class ExpertiseController < ApplicationController
  
  before_filter :login_required
  
  def show
    @expertise = Expertise.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @expertise }
    end
  end

  def index
  end

end
