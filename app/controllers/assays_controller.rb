class AssaysController < ApplicationController

  before_filter :login_required
  before_filter :is_project_member,:only=>[:create,:new]
  before_filter :delete_allowed,:only=>[:destroy]
  
  def index
    @assays=Assay.find(:all, :page=>{:size=>default_items_per_page,:current=>params[:page]}, :order=>'updated_at DESC')

    respond_to do |format|
      format.html
      format.xml {render :xml=>@assays}
    end
    
  end

  def new
    @assay=Assay.new
    @assay.study = Study.find(params[:study_id]) if params[:study_id]

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
    @assay.owner=current_user.person
    
    synchronise_created_datas(params[:data_file_ids])
    
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
    synchronise_created_datas(params[:data_file_ids])
    @assay.sops.clear unless params[:assay][:sop_ids]
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
    
    respond_to do |format|
      if @assay.study.nil? && @assay.destroy
        format.html { redirect_to(assays_url) }
        format.xml  { head :ok }
      else
        flash[:error]="Unable to delete the assay" if !@assay.study.nil?
        format.html { render :action=>"show" }
        format.xml  { render :xml => @assay.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def synchronise_created_datas data_file_ids
    for_removal=[]
    for_addition=[]

    data_files= data_file_ids ? DataFile.find(data_file_ids) : []
    
    for created_data in @assay.created_datas
      for_removal << created_data if !data_files.include?(created_data.data_file)
    end

    for data_file in data_files
      for_addition << CreatedData.new(:data_file=>data_file,:person=>current_user.person) if !@assay.data_files.include?(data_file)
    end

    @assay.created_datas = @assay.created_datas - for_removal
    @assay.created_datas = @assay.created_datas | for_addition
  end

  def delete_allowed
    @assay=Assay.find(params[:id])
    unless @assay.can_delete?(current_user)
      respond_to do |format|
        flash[:error] = "You cannot delete an assay that is linked to a Study, Data files or Sops"
        format.html { redirect_to assays_path }
      end
      return false
    end
  end


end
