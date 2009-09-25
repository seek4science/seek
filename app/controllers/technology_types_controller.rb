class TechnologyTypesController < ApplicationController

  before_filter :login_required
  before_filter :pal_or_admin_required,:except=>[:show]

  def show
    @technology_type = TechnologyType.find(params[:id])

    respond_to do |format|
      format.html
      format.xml { render :xml=>@technology_type}
    end

  end

  def new
    @technology_type=TechnologyType.new

    respond_to do |format|
      format.html
      format.xml  { render :xml => @technology_type }
    end
  end
  
  def manage
    @technology_types = TechnologyType.all
    #@technology_type = TechnologyType.last

    respond_to do |format|
      format.html
      format.xml {render :xml=>@technology_types}
    end
  end
  
  def edit
    @technology_type=TechnologyType.find(params[:id])

    respond_to do |format|
      format.html
      format.xml  { render :xml => @technology_type }
    end
  end
  
  def create
    @technology_type = TechnologyType.new(:title => params[:technology_type][:title])
    @technology_type.parents = params[:technology_type][:parent_id].collect {|p_id| TechnologyType.find_by_id(p_id)}
    #@technology_type.owner=current_user.person    
    
    respond_to do |format|
      if @technology_type.save        
        flash[:notice] = 'Technology type was successfully created.'
        format.html { redirect_to(:action => 'manage') }
        format.xml  { render :xml => @technology_type, :status => :created, :location => @technology_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @technology_type.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update
    @technology_type=TechnologyType.find(params[:id])

    respond_to do |format|
      if @technology_type.update_attributes(:title => params[:technology_type][:title])
        unless params[:technology_type][:parent_id] == @technology_type.parents.collect {|par| par.id}
          @technology_type.parents = params[:technology_type][:parent_id].collect {|p_id| TechnologyType.find_by_id(p_id)}
        end
        flash[:notice] = 'Technology type was successfully updated.'
        format.html { redirect_to(:action => 'manage') }
        format.xml  { head :ok }
      else
        format.html { redirect_to(:action => 'edit') }
        format.xml  { render :xml => @technology_type.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy    
    @technology_type=TechnologyType.find(params[:id])
    
    respond_to do |format|
      if @technology_type.assays.empty? && @technology_type.get_child_assays.empty? && @technology_type.children.empty?
        @technology_type.destroy
        flash[:notice] = 'Technology type was deleted.'
        format.html { redirect_to(:action => 'manage') }
        format.xml  { head :ok }
      else
        if !@technology_type.children.empty?
          flash[:error]="Unable to delete tecnology types with children" 
        elsif @technology_type.get_child_assays.empty?
          flash[:error]="Unable to delete tecnology type due to reliance from #{@technology_type.get_child_assays.count} existing assays on child assay types"
        elsif !@technology_type.assays.empty?
          flash[:error]="Unable to delete tecnology type due to reliance from #{@technology_type.get_child_assays.count} existing assays"        
        end
        format.html { redirect_to(:action => 'manage') }
        format.xml  { render :xml => @technology_type.errors, :status => :unprocessable_entity }
      end
    end
  end
  
end