class AssayTypesController < ApplicationController


  before_filter :find_ontology_class, :only=>[:show]
  before_filter :find_and_authorize_assays, :only=>[:show]

  def show
    respond_to do |format|
      format.html
      format.xml
    end
  end

   private

  def find_ontology_class
    uri = params[:uri] || Seek::Ontologies::AssayTypeReader.instance.default_parent_class_uri.to_s

    @is_modelling = false
    cls = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_uri[uri]

    if cls.nil?
      cls = Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_uri[uri]
      @is_modelling = true
    end

    if cls.nil?
      cls = SuggestedAssayType.where(:uri => uri).first
      @is_modelling = cls.try(:is_for_modelling)
    end

    if cls.nil?
      flash.now[:error] = "Unrecognised assay type"
    elsif !params[:label].blank? && params[:label].downcase != cls.label.downcase
      flash.now[:notice] = "Undefined assay type with label <b> #{params[:label]} </b>. Did you mean #{view_context.link_to(cls.label, assay_types_path(:uri=>uri, :label=> cls.label),{:style=> "font-style:italic;font-weight:bold;"})}?".html_safe
    else
      @type_class=cls
    end
    @label = params[:label] || @type_class.try(:label)

  end

  def find_and_authorize_assays
    @assays=[]
    if @type_class
      if @type_class.is_suggested_type?
        uris = ([@type_class] +@type_class.children).map(&:uri)
      else
        uris=@type_class.flatten_hierarchy.collect { |o| o.uri.to_s }
        uris |= SuggestedAssayType.where(:parent_uri=>@type_class.uri.to_s).map(&:uri)
      end
      assays = Assay.where(assay_type_uri: uris)
      @assays = Assay.authorize_asset_collection(assays, "view")
    end
  end

  def check_allowed_to_edit_types
    @assay_type=AssayType.find(params[:id])
    if !@assay_type.is_user_defined
       flash.now[:error] = "It cannot be edited, as it is extracted from external ontology!"
    end
  end



end
