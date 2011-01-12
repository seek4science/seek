require 'white_list_helper'

class InstitutionsController < ApplicationController
  include WhiteListHelper
  
  include IndexPager
  
  before_filter :login_required
  before_filter :find_institutions, :only=>[:index]
  before_filter :is_user_admin_auth, :except=>[:index, :show, :edit, :update, :request_all]
  before_filter :editable_by_user, :only=>[:edit,:update]

  cache_sweeper :institutions_sweeper,:only=>[:update,:create,:destroy]
  

  # GET /institutions/1
  # GET /institutions/1.xml
  def show
    @institution = Institution.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml
    end
  end

  # GET /institutions/new
  # GET /institutions/new.xml
  def new
    @institution = Institution.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @institution }
    end
  end

  # GET /institutions/1/edit
  def edit
    @institution = Institution.find(params[:id])
    
    possible_unsaved_data = "unsaved_#{@institution.class.name}_#{@institution.id}".to_sym
    if session[possible_unsaved_data]
      # if user was redirected to this 'edit' page from avatar upload page - use session
      # data; alternatively, user has followed some other route - hence, unsaved session
      # data is most probably not relevant anymore
      if params[:use_unsaved_session_data]
        # update those attributes of the institution that we want to be updated from the session
        @institution.attributes = session[possible_unsaved_data][:institution]
      end
      
      # clear the session data anyway
      session[possible_unsaved_data] = nil
    end
  end

  # POST /institutions
  # POST /institutions.xml
  def create
    @institution = Institution.new(params[:institution])

    respond_to do |format|
      if @institution.save
        flash[:notice] = 'Institution was successfully created.'
        format.html { redirect_to(@institution) }
        format.xml  { render :xml => @institution, :status => :created, :location => @institution }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @institution.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /institutions/1
  # PUT /institutions/1.xml
  def update
    @institution = Institution.find(params[:id])

    # extra check required to see if any avatar was actually selected (or it remains to be the default one)
    avatar_id = params[:institution].delete(:avatar_id).to_i
    @institution.avatar_id = ((avatar_id.kind_of?(Numeric) && avatar_id > 0) ? avatar_id : nil)

    respond_to do |format|
      if @institution.update_attributes(params[:institution])
        flash[:notice] = 'Institution was successfully updated.'
        format.html { redirect_to(@institution) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @institution.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /institutions/1
  # DELETE /institutions/1.xml
  def destroy
    @institution = Institution.find(params[:id])
    @institution.destroy

    respond_to do |format|
      format.html { redirect_to(institutions_url) }
      format.xml  { head :ok }
    end
  end

  
  # returns a list of all institutions in JSON format
  def request_all
    # listing all institutions is public data, but still
    # we require login to protect from unwanted requests
    
    institution_id = white_list(params[:id])
    institution_list = Institution.get_all_institutions_listing
    
    
    respond_to do |format|
      format.json {
        render :json => {:status => 200, :institution_list => institution_list }
      }
    end
  end

  private
  
  def find_institutions
    @institutions = Institution.paginate :page=>params[:page]
    @institutions = apply_filters(@institutions)
  end

  def editable_by_user
    @institution = Institution.find(params[:id])
    unless current_user.is_admin? || @institution.can_be_edited_by?(current_user)
      error("Insufficient privileged", "is invalid (insufficient_privileges)")
      return false
    end
  end

  def default_items_per_page
    12 #can be larger for institutions since the item size is smaller
  end
end
