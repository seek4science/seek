class AssayTypesController < ApplicationController

  before_filter :check_allowed_to_manage_types, :except=>[:show,:index]
  before_filter :find_requested_item, :only=>[:show]

  def show
    @assay_type = AssayType.find(params[:id])
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def new
    @assay_type=AssayType.new
    @assay_type.parent_name= params[:parent_name]
    respond_to do |format|
      format.html
      format.xml  { render :xml => @assay_type }
    end
  end
  
  def index
    @assay_types=AssayType.all
    respond_to do |format|
      format.xml
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
    @assay_type = AssayType.new(params[:assay_type].reject{|k,v|k=='parent_id'})
    @assay_type.parents = params[:assay_type][:parent_id].collect {|p_id| AssayType.find_by_id(p_id)}
    #@assay_type.owner=current_user.person    
    

      if @assay_type.save
        if @assay_type.parent_name == 'assay'
          render :partial => "assets/back_to_singleselect_parent",:locals => {:child=>@assay_type,:parent=>@assay_type.parent_name}
        else
         respond_to do |format|
          flash[:notice] = "#{t('assays.assay')} type was successfully created."
          format.html { redirect_to(:action => 'manage') }
          format.xml  { render :xml => @assay_type, :status => :created, :location => @assay_type }
           end
        end

      else
        respond_to do |format|
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
        flash[:notice] = "#{t('assays.assay')} type was successfully updated."
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
        flash[:notice] = "#{t('assays.assay')} type was deleted."
        format.html { redirect_to(:action => 'manage') }
        format.xml  { head :ok }
      else
        if !@assay_type.children.empty?
          flash[:error]="Unable to delete #{t('assays.assay').downcase} types with children"
        elsif !@assay_type.get_child_assays.empty?
          flash[:error]="Unable to delete #{t('assays.assay').downcase} type due to reliance from #{@assay_type.get_child_assays.count} existing #{t('assays.assay').downcase.pluralize} on child #{t('assays.assay').downcase} types"
        elsif !@assay_type.assays.empty?
          flash[:error]="Unable to delete #{t('assays.assay').downcase} type due to reliance from #{@assay_type.get_child_assays.count} existing #{t('assays.assay').downcase.pluralize}"
        end
        format.html { redirect_to(:action => 'manage') }
        format.xml  { render :xml => @assay_type.errors, :status => :unprocessable_entity }
      end
    end
  end
  
end