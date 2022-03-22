class HelpDocumentsController < ApplicationController

  include Seek::DestroyHandling

  before_action :documentation_enabled?
  before_action :internal_help_enabled
  before_action :find_document, :except => [:new, :index, :create]
  before_action :login_required, :except=>[:show,:index]
  before_action :is_user_admin_auth, :except => [:show, :index]
  
  def internal_help_enabled
    if (!Seek::Config.internal_help_enabled)
      redirect_to(Seek::Config.external_help_url)
    end
  end

  def index
    if (@help_document = HelpDocument.find_by_identifier("index"))
      respond_to do |format|
        format.html { redirect_to(@help_document) }
      end
    else
      @help_documents = HelpDocument.all
      respond_to do |format|
        format.html # index.html.erb
      end
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  def new
    @help_document = HelpDocument.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  def edit
  end
  
  def update
    #Update changes when previewing, but don't save
    if params[:commit] == "Preview"
      @preview = true
      @help_document.body = params[:help_document][:body]
      @help_document.title = params[:help_document][:title]
    end   
    respond_to do |format|
      if !@preview && @help_document.update(help_document_params)
        format.html { redirect_to(@help_document) }
      elsif @preview
        format.html { render :action => "edit" }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  def create
    @help_document = HelpDocument.new(help_document_params)
    if params[:commit] == "Preview"
      @preview = true
    end
    respond_to do |format|
      if !@preview && @help_document.save
        format.html { redirect_to(@help_document) }
      elsif @preview
        format.html { render :action => "new" }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  private

  def help_document_params
    permitted_params = [:title, :body]
    permitted_params << :identifier if action_name == 'create'
    params.require(:help_document).permit(permitted_params)
  end

  def find_document
    @help_document = HelpDocument.find_by_identifier(params[:id]) || raise(ActiveRecord::RecordNotFound)
  end
end
