class OrganismsController < ApplicationController

  include Seek::DestroyHandling

  before_filter :organisms_enabled?
  before_filter :find_requested_item, :only=>[:show,:edit,:more_ajax,:visualise,:destroy, :update]
  before_filter :login_required,:except=>[:show,:index,:visualise]
  before_filter :can_manage?,:only=>[:edit,:update]
  before_filter :auth_to_create, :only=>[:new,:create, :destroy]
  before_filter :find_assets, only: [:index]

  skip_before_filter :project_membership_required
  
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
      format.json {render json: @organism}
    end
  end

  def index

    if request.format.symbol == :html
      super
    else
      respond_to do |format|
        format.xml
        format.json {render json: @organisms,
                            each_serializer: SkeletonSerializer,
                            meta: {:base_url =>   Seek::Config.site_base_host,
                                   :api_version => ActiveModel::Serializer.config.api_version
        }}
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
    render :update do |page|
      if results
        page.replace_html 'search_results', :partial => "search_results",
                          :object => results, :locals => { :pages => pages, :pagenum => pagenum, :search_term => search_term }
      else
        page.replace_html 'search_results', :partial => "search_error", :locals => { :text => error || "Nothing found" }
      end
    end
  end

  def more_ajax    
    concept = @organism.concept
    render :update do |page|
      if concept
        page.replace_html 'bioportal_more',:partial=>"concept",:object=>concept
      else
        page.replace_html 'bioportal_more',:text=>"Nothing found"
      end
    end
  end

  def create
    @organism = Organism.new(organism_params)
    respond_to do |format|
      if @organism.save
        flash[:notice] = 'Organism was successfully created.'
        format.html { redirect_to organism_path(@organism) }
        format.xml  { head :ok }
        format.json {render json: @organism, status: :created, location: @organism}
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
        format.json {render json: @organism}
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
