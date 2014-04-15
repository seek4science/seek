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

    cls = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_uri[uri]
    cls ||= SuggestedAssayType.where(:uri => uri).first
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
      if is_suggested?(@type_class)
        uris = ([@type_class] +@type_class.children).map(&:uri)
      else
        uris=@type_class.flatten_hierarchy.collect { |o| o.uri.to_s }
        uris |= SuggestedAssayType.where(:parent_uri=>@type_class.uri.to_s)
      end
        assays = Assay.where(assay_type_uri: uris)
        @assays = Assay.authorize_asset_collection(assays, "view")
        @uris = uris
    end
  end

  def check_allowed_to_edit_types
    @assay_type=AssayType.find(params[:id])
    if !@assay_type.is_user_defined
       flash.now[:error] = "It cannot be edited, as it is extracted from external ontology!"
    end
  end


  def is_suggested? clz
      clz.is_a?(SuggestedAssayType)
  end
end
