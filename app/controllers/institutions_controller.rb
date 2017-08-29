class InstitutionsController < ApplicationController
  include WhiteListHelper
  include Seek::IndexPager
  include CommonSweepers
  include Seek::DestroyHandling

  before_filter :find_requested_item, only: [:show, :edit, :update, :destroy]
  before_filter :find_assets, only: [:index]
  before_filter :is_user_admin_auth, only: [:destroy]
  before_filter :editable_by_user, only: [:edit, :update]
  before_filter :auth_to_create, only: [:new, :create]

  skip_before_filter :project_membership_required

  cache_sweeper :institutions_sweeper, only: [:update, :create, :destroy]
  include Seek::BreadCrumbs

  # GET /institutions/1
  # GET /institutions/1.xml
  def show
    options = {:is_collection=>false}
    respond_to do |format|
      format.html # show.html.erb
      format.rdf { render template: 'rdf/show' }
      format.xml
      # format.json { render layout: false, json: JSON.parse(JbuilderTemplate.new(view_context).api_format!(@institution).target!) }
      #format.json { render json: @institution } #normal json
      format.json {render json: JSONAPI::Serializer.serialize(@institution,options)}
    end
  end

  # GET /institutions/new
  # GET /institutions/new.xml
  def new
    @institution = Institution.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @institution }
    end
  end

  # GET /institutions/1/edit
  def edit
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

    # convert params as recieved by json-api to (flat) rails json
    # if params.key?("data")
    #   params_new = params[:data][:attributes]
    #   params[:institution] = params_new
    # end
    @institution = Institution.new(institution_params)
    respond_to do |format|
      if @institution.save
        flash[:notice] = 'Institution was successfully created.'
        format.html { redirect_to(@institution) }
        format.xml  { render xml: @institution, status: :created, location: @institution }
      else
        format.html { render action: 'new' }
        format.xml  { render xml: @institution.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /institutions/1
  # PUT /institutions/1.xml
  def update
    respond_to do |format|
      if @institution.update_attributes(institution_params)
        expire_resource_list_item_content
        flash[:notice] = 'Institution was successfully updated.'
        format.html { redirect_to(@institution) }
        format.xml  { head :ok }
      else
        format.html { render action: 'edit' }
        format.xml  { render xml: @institution.errors, status: :unprocessable_entity }
      end
    end
  end

  # returns a list of all institutions in JSON format
  def request_all
    # listing all institutions is public data, but still
    # we require login to protect from unwanted requests
    options = {:is_collection=>true}
    institution_id = white_list(params[:id])
    institution_list = Institution.get_all_institutions_listing
    respond_to do |format|
       format.json do
         render json: JSONAPI::Serializer.serialize(institution_list, options)
         #render json: { status: 200, institution_list: institution_list }
       end
    end
  end

  private

  def institution_params
    params.require(:institution).permit(:title, :web_page, :address, :city, :country)
  end

  def editable_by_user
    @institution = Institution.find(params[:id])
    unless User.admin_logged_in? || @institution.can_be_edited_by?(current_user)
      error('Insufficient privileges', 'is invalid (insufficient_privileges)')
      return false
    end
  end
end
