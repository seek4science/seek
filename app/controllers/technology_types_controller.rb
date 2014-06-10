class TechnologyTypesController < ApplicationController
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
    uri = params[:uri] || Seek::Ontologies::TechnologyTypeReader.instance.default_parent_class_uri.to_s
    cls = Seek::Ontologies::TechnologyTypeReader.instance.class_hierarchy.hash_by_uri[uri]
    cls ||= SuggestedTechnologyType.where(:uri => uri).first
    if cls.nil?
      flash.now[:error] = "Unrecognised technology type"
    elsif !params[:label].blank? && params[:label].downcase != cls.label.downcase
      flash.now[:notice] = "Undefined technology type with label <b> #{params[:label]} </b>. Did you mean #{view_context.link_to(cls.label, technology_types_path(:uri=>uri, :label=> cls.label),{:style=> "font-style:italic;font-weight:bold;"})}?".html_safe
    else
      @type_class=cls
    end
    @label = params[:label] || @type_class.try(:label)
  end

  def find_and_authorize_assays
    @assays=[]
    if @type_class
      if view_context.is_suggested?(@type_class)
         uris = ([@type_class] +@type_class.children).map(&:uri)
      else
         uris=@type_class.flatten_hierarchy.collect{|o| o.uri.to_s}
      end
      assays = Assay.where(technology_type_uri: uris)
      @assays = Assay.authorize_asset_collection(assays,"view")
      @uris = uris
    end
  end


end