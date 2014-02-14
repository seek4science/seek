class AssayTypesController < ApplicationController

  before_filter :check_allowed_to_manage_types, :except=>[:show,:index]
  before_filter :find_ontology_class, :only=>[:show]
  before_filter :find_and_authorize_assays, :only=>[:show]
  before_filter :check_allowed_to_edit_types, :only=> [:edit]

  def show
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
    @assay_type = AssayType.new(params[:assay_type])


      if @assay_type.save
        if @assay_type.parent_name == 'assay'
          render :partial => "assets/back_to_singleselect_parent",:locals => {:child=>@assay_type,:parent=>@assay_type.parent_name,:child_list_id=> "assay_assay_type_uri" }
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
      if @assay_type.save

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
   private

  def find_ontology_class
    uri = params[:uri] || Seek::Ontologies::AssayTypeReader.instance.default_parent_class_uri.to_s

    cls = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_uri[uri]
    @is_modelling = cls.nil?
    cls ||= Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_uri[uri]
    if cls.nil?
      flash.now[:error] = "Unrecognised assay type"
    else
      @type_class=cls
    end
    @label = params[:label] || @type_class.try(:label)

  end

  def find_and_authorize_assays
    @assays=[]
    if @type_class
      uris=@type_class.flatten_hierarchy.collect{|o| o.uri.to_s}
      assays = Assay.where(assay_type_uri: uris)
      @assays = Assay.authorize_asset_collection(assays,"view")
      @uris = uris
    end
  end

  def check_allowed_to_edit_types
    @assay_type=AssayType.find(params[:id])
    if !@assay_type.source_path.blank?
       flash.now[:error] = "It cannot be edited, as it is extracted from external ontology!"
    end
  end
  
  
end
