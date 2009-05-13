class AssaysController < ApplicationController

  before_filter :login_required
  before_filter :is_project_member,:only=>[:create,:new]
  
  def new
    @assay=Assay.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @assay }
    end
  end

  def edit
    @assay=Assay.find(params[:id])

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

  def update
    @assay=Assay.find(params[:id])

    respond_to do |format|
      if @assay.update_attributes(params[:assay])
        flash[:notice] = 'Assay was successfully updated.'
        format.html { redirect_to(@assay) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
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

  def destroy
    @assay=Assay.find(params[:id])
    respond_to do |format|
      if @assay.studies.empty? && @assay.destroy
        format.html { redirect_to(assays_url) }
        format.xml  { head :ok }
      else
        flash[:error]="Unable to delete the assay" if !@assay.studies.empty?
        format.html { render :action=>"show" }
        format.xml  { render :xml => @assay.errors, :status => :unprocessable_entity }
      end
    end
  end

end
