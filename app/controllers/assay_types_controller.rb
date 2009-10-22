class AssayTypesController < ApplicationController

  before_filter :login_required
  before_filter :is_user_admin_auth,:except=>[:show]

  def show
    @assay_type = AssayType.find(params[:id])

    respond_to do |format|
      format.html
      format.xml { render :xml=>@assay_type}
    end

  end

  def new
    @assay_type=AssayType.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @assay_type }
    end
  end
  
  def manage
    @assay_types = AssayType.all
    #@assay_type = AssayType.last

    respond_to do |format|
      format.html
      format.xml {render :xml=>@assay_types}
    end
  end
  
  def edit
    @assay_type=AssayType.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @assay_type }
    end
  end
  
  def create
    @assay_type = AssayType.new(:title => params[:assay_type][:title])
    @assay_type.parents = params[:assay_type][:parent_id].collect {|p_id| AssayType.find_by_id(p_id)}
    #@assay_type.owner=current_user.person    
    
    respond_to do |format|
      if @assay_type.save        
        flash[:notice] = 'Assay type was successfully created.'
        format.html { redirect_to(:action => 'manage') }
        format.xml  { render :xml => @assay_type, :status => :created, :location => @assay_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @assay_type.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update
    @assay_type=AssayType.find(params[:id])

    respond_to do |format|
      if @assay_type.update_attributes(:title => params[:assay_type][:title])
        unless params[:assay_type][:parent_id] == @assay_type.parents.collect {|par| par.id}
          @assay_type.parents = params[:assay_type][:parent_id].collect {|p_id| AssayType.find_by_id(p_id)}
        end
        flash[:notice] = 'Assay type was successfully updated.'
        format.html { redirect_to(:action => 'manage') }
        format.xml  { head :ok }
      else
        format.html { redirect_to(:action => 'edit') }
        format.xml  { render :xml => @assay_type.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy    
    @assay_type=AssayType.find(params[:id])
    
    respond_to do |format|
      if @assay_type.assays.empty? && @assay_type.get_child_assays.empty? && @assay_type.children.empty?
        @assay_type.destroy
        flash[:notice] = 'Assay type was deleted.'
        format.html { redirect_to(:action => 'manage') }
        format.xml  { head :ok }
      else
        if !@assay_type.children.empty?
          flash[:error]="Unable to delete assay types with children" 
        elsif @assay_type.get_child_assays.empty?
          flash[:error]="Unable to delete assay type due to reliance from #{@assay_type.get_child_assays.count} existing assays on child assay types"
        elsif !@assay_type.assays.empty?
          flash[:error]="Unable to delete assay type due to reliance from #{@assay_type.get_child_assays.count} existing assays"        
        end
        format.html { redirect_to(:action => 'manage') }
        format.xml  { render :xml => @assay_type.errors, :status => :unprocessable_entity }
      end
    end
  end
  
end