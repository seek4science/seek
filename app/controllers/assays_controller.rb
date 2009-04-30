class AssaysController < ApplicationController

  before_filter :login_required
  
  def new
    @assay=Assay.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @assay }
    end
  end

  def create
    @assay = Assay.new(params[:assay])

    respond_to do |format|
      if @assay.save
        flash[:notice] = 'Assay was successfully created.'
        format.html { redirect_to(@assay) }
        format.xml  { render :xml => @assay, :status => :created, :location => @assay }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @assay.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @assay=Assay.find(params[:id])

    respond_to do |format|
      format.html
      format.xml { render :xml => @assay, :include=>[:assay_type,:sops]}
    end

  end

end
