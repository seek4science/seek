class AssaysController < ApplicationController

  def new
    @assay=Assay.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @assay }
    end
  end

end
