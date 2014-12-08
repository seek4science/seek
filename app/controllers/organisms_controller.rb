class OrganismsController < ApplicationController

  include Seek::DestroyHandling

  before_filter :organisms_enabled?
  before_filter :find_requested_item, :only=>[:show,:edit,:more_ajax,:visualise,:destroy, :update]
  before_filter :login_required,:except=>[:show,:index,:visualise]
  before_filter :is_user_admin_auth,:only=>[:edit,:update,:new,:create,:destroy]
  
  cache_sweeper :organisms_sweeper,:only=>[:update,:create,:destroy]

  include BioPortal::RestAPI

  def show
    respond_to do |format|
      format.html
      format.xml
      format.rdf { render :template=>'rdf/show'}
    end
  end

  def index
    @organisms=Organism.all
    respond_to do |format|
      format.xml
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
    results,pages = search search_term,{:isexactmatch=>0,:pagesize=>50,:pagenum=>pagenum,:ontologies=>"NCBITAXON",:apikey=>Seek::Config.bioportal_api_key}
    render :update do |page|
      if results
        page.replace_html 'search_results',:partial=>"search_results",:object=>results,:locals=>{:pages=>pages,:pagenum=>pagenum,:search_term=>search_term}
      else
        page.replace_html 'search_results',:text=>"Nothing found"
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
    @organism = Organism.new(params[:organism])
    respond_to do |format|
      if @organism.save
        flash[:notice] = 'Organism was successfully created.'
        format.html { redirect_to organism_path(@organism) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organism.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update

    respond_to do |format|
      if @organism.update_attributes(params[:organism])
        flash[:notice] = 'Organism was successfully updated.'
        format.html { redirect_to organism_path(@organism) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organism.errors, :status => :unprocessable_entity }
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
  
end
