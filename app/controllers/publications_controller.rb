class PublicationsController < ApplicationController

  
  # GET /publications
  # GET /publications.xml
  def index
    @publications = Publication.paginate :page=>params[:page], :default_page => "all"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @publications }
    end
  end

  # GET /publications/1
  # GET /publications/1.xml
  def show
    @publication = Publication.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @publication }
    end
  end

  # GET /publications/new
  # GET /publications/new.xml
  def new
    respond_to do |format|
      format.html # new.html.erb
      format.xml 
    end
  end

  # GET /publications/1/edit
  def edit
    @publication = Publication.find(params[:id])
  end

  # POST /publications
  # POST /publications.xml
  def create
    @publication = Publication.new(params[:publication])
    @publication.contributor = current_user

    respond_to do |format|
      if @publication.save
        flash[:notice] = 'Publication was successfully created.'
        format.html { redirect_to(@publication) }
        format.xml  { render :xml => @publication, :status => :created, :location => @publication }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @publication.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /publications/1
  # PUT /publications/1.xml
  def update
    @publication = Publication.find(params[:id])

    respond_to do |format|
      if @publication.update_attributes(params[:publication])
        flash[:notice] = 'Publication was successfully updated.'
        format.html { redirect_to(@publication) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @publication.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /publications/1
  # DELETE /publications/1.xml
  def destroy
    @publication = Publication.find(params[:id])
    @publication.destroy

    respond_to do |format|
      format.html { redirect_to(publications_url) }
      format.xml  { head :ok }
    end
  end
  
  def fetch_preview
    @publication = Publication.new
    pubmed_id = params[:pubmed_id]
    query = PubmedQuery.new("sysmo-seek","")
    results = query.fetch([pubmed_id])
    unless results.empty?
      result = results.first
      @publication = Publication.new    
      @publication.extract_metadata(result) unless result.nil?
    else
      raise "Error - No pubmed record found"
    end
    respond_to do |format|
      format.html { render :partial => "publications/publication_preview", :locals => { :publication => @publication, :authors => result.authors} }
    end
  end
end