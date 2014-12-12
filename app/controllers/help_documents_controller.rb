class HelpDocumentsController < ApplicationController

  include Seek::DestroyHandling

  before_filter :documentation_enabled?
  before_filter :find_document, :except => [:new, :index, :create]
  before_filter :login_required, :except=>[:show,:index]
  before_filter :is_user_admin_auth, :except => [:show, :index]
  
  def index
    if (@help_document = HelpDocument.find_by_identifier("index"))
      respond_to do |format|
        format.html { redirect_to(@help_document) }
        format.xml { render :xml=>@help_document}
      end
    else
      @help_documents = HelpDocument.all
      respond_to do |format|
        format.html # index.html.erb
        format.xml { render :xml=>@help_documents}
      end
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml=>@help_document}
    end
  end
  
  def new
    @help_document = HelpDocument.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @help_document }
    end
  end
  
  def edit
  end
  
  def update
    #Stop identifier being changed
    params[:help_document].delete(:identifier)
    
    #Update changes when previewing, but don't save
    if params[:commit] == "Preview"
      @preview = true
      @help_document.body = params[:help_document][:body]
      @help_document.title = params[:help_document][:title]
    end   
    respond_to do |format|
      if !@preview && @help_document.update_attributes(params[:help_document])
        format.html { redirect_to(@help_document) }
        format.xml  { head :ok }
      elsif @preview
        format.html { render :action => "edit" }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @help_document.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def create
    @help_document = HelpDocument.new(params[:help_document]) 
    if params[:commit] == "Preview"
      @preview = true
    end
    respond_to do |format|
      if !@preview && @help_document.save
        format.html { redirect_to(@help_document) }
        format.xml  { render :xml => @help_document, :status => :created, :location => @help_document }
      elsif @preview
        format.html { render :action => "new" }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @help_document.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  private
  
  def find_document
    @help_document = HelpDocument.find_by_identifier(params[:id]) || raise(ActiveRecord::RecordNotFound)
  end
end