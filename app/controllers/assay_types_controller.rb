class AssayTypesController < ApplicationController

  before_filter :check_allowed_to_manage_types, :except=>[:show]
  before_filter :find_ontology_class, :only=>[:show]
  before_filter :find_and_authorize_assays, :only=>[:show]
  before_filter :check_allowed_to_edit_types, :only=> [:edit]

  #update term uri when changing parent. Using ajax request instead of callbacks to avoid affecting those created/updated from ontology
  def update_term_uri
      parent = AssayType.find params[:parent_id]
      render :update do |page|
        page[:assay_type_term_uri].value = parent.term_uri if parent
      end
  end

  def show
    respond_to do |format|
      format.html
      format.xml
    end
  end


  def new
    @assay_type=AssayType.new
    @assay_type.default_parent_id =  params[:default_parent_id]
    @assay_type.link_from= params[:link_from]
    respond_to do |format|
      format.html{render :partial => "assay_types/new_popup"  }
      format.xml  { render :xml => @assay_type }
    end
  end



  
  def manage
    @assay_types = AssayType.all
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
    #TODO: assay type has parents, but only allow user select one parent for the first step.
    # this is try to convert parents string to be string array, e.g.. "1" --> ["1"]
    @assay_type.parent_ids = params[:assay_type][:parent_ids].split if params[:assay_type][:parent_ids]


        render :update do |page|
          if @assay_type.save
                      page.call 'RedBox.close'
                      if @assay_type.link_from == "assays"
                        page.replace_html 'assay_assay_types_list',:partial => "assays/assay_types_list", :locals=>{:assay_type=>@assay_type, :root_id=> @assay_type.default_parent_id}
                      elsif @assay_type.link_from == "assay_types"
                        page.redirect_to(:controller=>"assay_types", :action=>"manage")
                      end
          else
               page.alert("Fail to create new assay type. #{@assay_type.errors.full_messages}")
          end

        end

  end
  
  def update
    @assay_type=AssayType.find(params[:id])
    @assay_type.attributes = params[:assay_type]
    @assay_type.parent_ids = params[:assay_type][:parent_ids].split if params[:assay_type][:parent_ids]

    respond_to do |format|
      if @assay_type.save

        flash[:notice] = "#{t('assays.assay')} type was successfully updated."
        format.html { redirect_to(:action => 'manage') }
        format.xml  { head :ok }
      else
        format.html { render :action=>:edit }
        format.xml  { render :xml => @assay_type.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy    
    @assay_type=AssayType.find(params[:id])
    
    respond_to do |format|
      if @assay_type.assays.empty? && @assay_type.get_child_assays.empty? && @assay_type.children.empty?
        title = @assay_type.title
        @assay_type.destroy
        flash[:notice] = "#{t('assays.assay')} type #{title} was deleted."
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
    @assay_type = AssayType.where({:title => params[:label], :term_uri=> params[:uri]}).first || AssayType.ontology_root

    uri = @assay_type.term_uri|| Seek::Ontologies::AssayTypeReader.instance.default_parent_class_uri.to_s

    cls = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_uri[uri]
    @is_modelling = cls.nil?
    cls ||= Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_uri[uri]
    cls ||= AssayType.ontology_root
    if cls.nil?
      flash.now[:error] = "Unrecognised assay type"
    else
      @type_class=cls
    end
    @label = @assay_type.title || @type_class.try(:label)
    @parents = @assay_type.is_user_defined ? AssayType.where({:title => @type_class.try(:label), :term_uri=> uri})  : @assay_type.parents
  end


  def find_and_authorize_assays
    @assays = Assay.authorize_asset_collection(@assay_type.assays,"view")
  end

  def check_allowed_to_edit_types
    @assay_type=AssayType.find(params[:id])
    if !@assay_type.is_user_defined
       flash.now[:error] = "It cannot be edited, as it is extracted from external ontology!"
    end
  end

  
end
