class AssaysController < ApplicationController

  before_filter :login_required
  before_filter :is_project_member,:only=>[:create,:new]
  before_filter :delete_allowed,:only=>[:destroy]
  
  def index
    @assays=Assay.find(:all, :page=>{:size=>default_items_per_page,:current=>params[:page]}, :order=>'updated_at DESC')
    @assays=Assay.paginate :page=>params[:page]

    respond_to do |format|
      format.html
      format.xml {render :xml=>@assays}
    end
    
  end

  def new
    @assay=Assay.new
    @assay.study = Study.find(params[:study_id]) if params[:study_id]
    @assay_class=params[:class]
    @assay.assay_class=AssayClass.for_type(@assay_class) unless @assay_class.nil?
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
    
    sop_assets = params[:assay_sop_asset_ids] || []
    data_assets = params[:assay_data_file_asset_ids] || []
    model_assets = params[:assay_model_asset_ids] || []
    (sop_assets+model_assets).each do |a_id|
      @assay.assets << Asset.find(a_id)
    end    

    @assay.owner=current_user.person       
    
    respond_to do |format|
      if @assay.save
        data_assets.each do |text|
          a_id, r_type = text.split(",")
          @assay.relate(Asset.find(a_id), RelationshipType.find_by_title(r_type))
        end    
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
    
    @assay.sops.clear unless params[:assay][:sop_ids]
    
    @assay.assets = []
    sop_assets = params[:assay_sop_asset_ids] || []
    data_assets = params[:assay_data_file_asset_ids] || []
    model_assets = params[:assay_model_asset_ids] || []
    (sop_assets+model_assets).each do |a_id|
      @assay.assets << Asset.find(a_id)
    end      
    data_assets.each do |text|
      a_id, r_type = text.split(",")
      relationship_type = RelationshipType.find_by_title(r_type)
      assay_asset = AssayAsset.new()
      assay_asset.assay = @assay
      assay_asset.asset = Asset.find(a_id)
      assay_asset.relationship_type = relationship_type      
      assay_asset.save
    end   
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
      if @assay.can_delete?(current_user) && @assay.destroy
        format.html { redirect_to(assays_url) }
        format.xml  { head :ok }
      else
        flash.now[:error]="Unable to delete the assay" if !@assay.study.nil?
        format.html { render :action=>"show" }
        format.xml  { render :xml => @assay.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update_types
    render :update do |page|
      page.replace_html "favourite_list", :partial=>"favourites/gadget_list"
    end
  end

  private  

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
