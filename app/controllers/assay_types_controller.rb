class AssayTypesController < ApplicationController

  #before_filter :find_requested_item, :only=>[:show]
  before_filter :find_ontology_class, :only=>[:show]
  before_filter :find_and_authorize_assays, :only=>[:show]

  def show
    @label = params[:label]
    respond_to do |format|
      format.html
      format.xml
    end
  end

  private

  def find_ontology_class
    uri = params[:uri]
    cls = Seek::Ontologies::AssayTypeReader.instance.class_hierarchy.hash_by_uri[uri]
    @is_modelling = cls.nil?
    cls ||= Seek::Ontologies::ModellingAnalysisTypeReader.instance.class_hierarchy.hash_by_uri[uri]
    if cls.nil?
      flash[:error] = "Unrecognised assay type"
    else
      @type_class=cls
    end
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

  
end