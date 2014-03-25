class TechnologyTypesController < ApplicationController
  before_filter :find_ontology_class, :only=>[:show]
  before_filter :find_and_authorize_assays, :only=>[:show]

  before_filter :check_allowed_to_manage_types, :except=>[:show]

  def update_term_uri
     parent = TechnologyType.find params[:parent_id]
      render :update do |page|
        page[:technology_type_term_uri].value = parent.term_uri if parent
      end
  end
  def show
    respond_to do |format|
      format.html
      format.xml
    end
  end
  def new
      @technology_type=TechnologyType.new
      @technology_type.link_from= params[:link_from]
      respond_to do |format|
        format.html { render :partial=>"technology_types/new_popup" }
        format.xml  { render :xml => @technology_type }
      end
    end

    def manage
      @technology_types = TechnologyType.all

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
    @technology_type = TechnologyType.new(params[:technology_type])
    @technology_type.parent_ids = params[:technology_type][:parent_ids].split if params[:technology_type][:parent_ids]

    render :update do |page|
      if @technology_type.save
        if @technology_type.link_from == "assays"
          page.replace_html 'assay_technology_types_list', :partial => "assays/technology_types_list", :locals => {:technology_type => @technology_type}
        elsif @technology_type.link_from == "technology_types"
          page.redirect_to(:controller => "technology_types", :action => "manage")
        end
      else
        page.alert("Fail to create new technology_type type. #{@technology_type.errors.full_messages}")
      end

    end


  end

    def update
      @technology_type=TechnologyType.find(params[:id])
      @technology_type.attributes = params[:technology_type]
      @technology_type.parent_ids = params[:technology_type][:parent_ids].split if params[:technology_type][:parent_ids]
      respond_to do |format|
        if @technology_type.save

          flash[:notice] = 'Technology type was successfully updated.'
          format.html { redirect_to(:action => 'manage') }
          format.xml  { head :ok }
        else
          format.html {  render :action=>:edit  }
          format.xml  { render :xml => @technology_type.errors, :status => :unprocessable_entity }
        end
      end
    end

    def destroy
      @technology_type=TechnologyType.find(params[:id])

      respond_to do |format|
        if @technology_type.assays.empty? && @technology_type.get_child_assays.empty? && @technology_type.children.empty?
          title = @technology_type.title
          @technology_type.destroy
          flash[:notice] = "Technology type #{title} was deleted."
          format.html { redirect_to(:action => 'manage') }
          format.xml  { head :ok }
        else
          if !@technology_type.children.empty?
            flash[:error]="Unable to delete technology types with children"
          elsif !@technology_type.get_child_assays.empty?
            flash[:error]="Unable to delete technology type due to reliance from #{@technology_type.get_child_assays.count} existing #{t('assays.assay').downcase.pluralize} on child technology types"
          elsif !@technology_type.assays.empty?
            flash[:error]="Unable to delete technology type due to reliance from #{@technology_type.get_child_assays.count} existing #{t('assays.assay').downcase.pluralize}"
          end
          format.html { redirect_to(:action => 'manage') }
          format.xml  { render :xml => @technology_type.errors, :status => :unprocessable_entity }
        end
      end
    end

  private

  def find_ontology_class
    @technology_type = TechnologyType.where({:title => params[:label], :term_uri=> params[:uri]}).first || TechnologyType.ontology_root
    uri = @technology_type.term_uri || Seek::Ontologies::TechnologyTypeReader.instance.default_parent_class_uri.to_s
    cls = Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_uri[uri]
    cls ||= TechnologyType.ontology_root
    if cls.nil?
      flash.now[:error] = "Unrecognised technology type"
    else
      @type_class=cls
    end
    @label = @technology_type.label || @type_class.try(:label)
    @parents = @technology_type.is_user_defined ? TechnologyType.where({:title => @type_class.try(:label), :term_uri=> uri})  : @technology_type.parents
  end

  def find_and_authorize_assays
      @assays = Assay.authorize_asset_collection(@technology_type.assays,"view")
  end
  

  
end