class OrganismsController < ApplicationController

  include Seek::DestroyHandling

  before_action :organisms_enabled?
  before_action :find_requested_item, :only=>[:show,:edit,:visualise,:destroy, :update]
  before_action :login_required,:except=>[:show,:index,:visualise]
  before_action :can_manage?,:only=>[:edit,:update]
  before_action :auth_to_create, :only=>[:new,:create, :destroy]
  before_action :find_assets, only: [:index]

  skip_before_action :project_membership_required
  
  cache_sweeper :organisms_sweeper,:only=>[:update,:create,:destroy]

  include BioPortal::RestAPI
  include Seek::ExternalServiceWrapper
  include Seek::IndexPager
  include Seek::BreadCrumbs

  def show
    respond_to do |format|
      format.html
      format.xml
      format.rdf { render :template=>'rdf/show'}
      format.json {render json: @organism, include: [params[:include]]}
    end
  end

  def visualise
    @no_sidebar=true
    respond_to do |format|
      format.html
    end
  end

  def new
    @organism=Organism.new
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
      results,pages = search search_term,{:isexactmatch=>0,:pagesize=>100,:page=>pagenum,:ontologies=>"NCBITAXON",:apikey=>Seek::Config.bioportal_api_key}
    end
    if results
      render :partial => "search_results",
                        :object => results, :locals => { :pages => pages, :pagenum => pagenum, :search_term => search_term }
    else
      render :partial => "search_error", :locals => { :text => error || "Nothing found" }
    end
  end

  def create
    @organism = Organism.new(organism_params)
    respond_to do |format|
      if @organism.save
        flash[:notice] = 'Organism was successfully created.'
        format.html { redirect_to organism_path(@organism) }
        format.xml  { head :ok }
        format.json {render json: @organism, status: :created, location: @organism, include: [params[:include]]}
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @organism.errors, :status => :unprocessable_entity }
        format.json  { render json: @organism.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def update

    respond_to do |format|
      if @organism.update_attributes(organism_params)
        flash[:notice] = 'Organism was successfully updated.'
        format.html { redirect_to organism_path(@organism) }
        format.xml  { head :ok }
        format.json {render json: @organism, include: [params[:include]]}
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organism.errors, :status => :unprocessable_entity }
        format.json  { render json: @organism.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.xml {render :xml=>@organism}
    end
  end

  private

  def organism_params
    params.require(:organism).permit(:title, :ontology_id, :concept_uri)
  end

  def can_manage?
    unless @organism.can_manage?
      error("Admin rights required", "is invalid (not admin)")
      false
    end
    true
  end
  
end
