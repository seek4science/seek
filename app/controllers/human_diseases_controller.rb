class HumanDiseasesController < ApplicationController
  include Seek::DestroyHandling

  before_action :human_diseases_enabled?
  before_action :find_requested_item, :only=>[:show,:tree,:edit,:visualise,:destroy, :update]
  before_action :login_required,:except=>[:show,:tree,:index,:visualise]
  before_action :can_manage?,:only=>[:edit,:update]
  before_action :auth_to_create, :only=>[:new,:create, :destroy]
  before_action :find_assets, only: [:index]

  skip_before_action :project_membership_required

  cache_sweeper :human_diseases_sweeper,:only=>[:update,:create,:destroy]

  include BioPortal::RestAPI
  include Seek::ExternalServiceWrapper
  include Seek::IndexPager
  include Seek::BreadCrumbs

  def show
    respond_to do |format|
      format.html
      format.xml
      format.rdf { render :template=>'rdf/show'}
      format.json {render json: @human_disease}
    end
  end

  def tree
    render json: human_diseases_tree(@human_disease).to_json
  end

  def index
    if request.format.html?
      super
    else
      respond_to do |format|
        format.xml
        format.json {
          render json: HumanDisease.includes(:parents).where('human_disease_parents': { parent_id: nil }).map { |r|
            node = r.to_node
            if node
              node['state'] = { opened: true }
              node
            end
          }.compact.to_json
        }
      end
    end
  end

  def visualise
    @no_sidebar=true
    respond_to do |format|
      format.html
    end
  end

  def new
    @human_disease=HumanDisease.new
    respond_to do |format|
      format.html
    end
  end

  def search_ajax
    pagenum=params[:pagenum]
    pagenum||=1
    search_term=params[:search_term]
    results, pages, error = nil
    wrap_service('BioPortal', proc { |m| error = m }) do
      results,pages = search search_term,{:isexactmatch=>0,:pagesize=>100,:page=>pagenum,:ontologies=>"DOID",:apikey=>Seek::Config.bioportal_api_key}
    end
    if results
      render :partial => "search_results",
             :object => results,
             :locals => { :pages => pages, :pagenum => pagenum, :search_term => search_term }
    else
      render :partial => "search_error", :locals => { :text => error || "Nothing found" }
    end
  end

  def create
    @human_disease = HumanDisease.new(human_disease_params)
    respond_to do |format|
      if @human_disease.save
        flash[:notice] = 'Human Disease was successfully created.'
        format.html { redirect_to human_disease_path(@human_disease) }
        format.xml  { head :ok }
        format.json {render json: @human_disease, status: :created, location: @human_disease}
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @human_disease.errors, :status => :unprocessable_entity }
        format.json  { render json: @human_disease.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def update

    respond_to do |format|
      if @human_disease.update_attributes(human_disease_params)
        flash[:notice] = 'Human Disease was successfully updated.'
        format.html { redirect_to human_disease_path(@human_disease) }
        format.xml  { head :ok }
        format.json {render json: @human_disease}
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @human_disease.errors, :status => :unprocessable_entity }
        format.json  { render json: @human_disease.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.xml {render :xml=>@human_disease}
    end
  end

  private

  def human_disease_params
    params.require(:human_disease).permit(:title, :ontology_id, :concept_uri)
  end

  def can_manage?
    unless @human_disease.can_manage?
      error("Admin rights required", "is invalid (not admin)")
      false
    end
    true
  end

  def human_diseases_tree(human_disease)
    nodes = []
    return nodes unless human_disease

    if human_disease.parents.empty?
      nodes.push(human_disease.to_node(human_disease, true))
    else
      human_disease.parents.each do |parent|
        nodes.push(parent.to_node(human_disease, true))
      end
    end

    nodes
  end
end
