class AvatarsController < ApplicationController
  skip_before_action :project_membership_required

  before_action :login_required, except: [:show]
  before_action :fetch_owner
  before_action :authorize_owner, except: [:show]
  before_action :find_avatars, only: [:index]
  before_action :find_avatar, only: [:show, :select, :edit, :update, :destroy]

  cache_sweeper :avatars_sweeper, only: [:destroy,:select,:create]

  protect_from_forgery except: [:new]

  include Seek::BreadCrumbs

  # GET /people/1/avatars/new
  # GET /people/new
  def new
    store_unsaved_person_proj_inst_data_to_session

    @avatar = @avatar_owner_instance.avatars.build
  end

  # POST /people/1/avatars
  # POST /people
  def create
    # the creation of the new Avatar instance needs to have only one parameter - therefore, the rest should be set separately
    @avatar = @avatar_owner_instance.avatars.build(avatar_params)
    @avatar.original_filename = (params[:avatar][:image_file]).original_filename

    respond_to do |format|
      if @avatar.save
        flash[:notice] = 'Avatar was successfully uploaded.'
        # updated to take account of possibly various locations from where this method can be called,
        # so multiple redirect options are possible -> now return link is passed as a parameter
        format.html { redirect_to(params[:return_to] + "?use_unsaved_session_data=true") }
      else
        format.html { render action: 'new' }
      end
    end
  end

  # GET /users/1/avatars/1
  # GET /avatars/1 -> denied by before_action
  def show
    params[:size] ||= "200x200"
    if params[:size] == "large"
      size = LARGE_SIZE
    else
      size = params[:size]
    end

    @avatar.resize_image(size)

    avatar_format = Avatar.image_storage_format.to_s

    respond_to do |format|
      format.html do
        send_file(@avatar.full_cache_path(size), :type => "image/#{avatar_format}", :disposition => 'inline')
      end
      format.xml do
        @cache_file=@avatar.full_cache_path(size)
        @type="image/#{avatar_format}"
      end
    end

  end

  # GET /users/1/avatars
  # GET /avatars -> denied by before_action
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end

  # DELETE /users/1/avatars/1
  # DELETE /avatars/1 -> denied by before_action
  def destroy
    owner = @avatar.owner

    @avatar.destroy

    respond_to do |format|
      format.html { redirect_to polymorphic_path([owner, :avatars]) }
    end
  end

  # GET /users/1/avatars/1/select
  # GET /avatars/1/select -> denied by before_action
  def select
    if @avatar.select!
      ## IN CONTRAST TO myExperiment SysMO WILL NOT STORE PICTURE SELECTIONS (AT LEAST FOR NOW)
      # create and save picture selection record
      # PictureSelection.create(:user => current_user, :picture => @picture)
      ## END

      @avatar.save #forces a update callback, which invokes the sweeper
      if @avatar_owner_instance.is_a?(Project)
        if (Seek::Config.email_enabled && !@avatar_owner_instance.can_manage?(current_user))
          ProjectChangedEmailJob.new(@avatar_owner_instance).queue_job
        end
      end
      respond_to do |format|
        flash[:notice] = 'Profile avatar was successfully updated.'
        format.html { redirect_to polymorphic_path([@avatar_owner_instance, :avatars]) }
      end
    else
      respond_to do |format|
        flash[:error] = "Avatar was already selected."
        format.html { redirect_to url_for(@avatar_owner_instance) }
      end
    end
  end

  private

  def fetch_owner
    get_parent_resource
    raise ActiveRecord::RecordNotFound unless @parent_resource
    @avatar_owner_instance = @parent_resource # legacy
  end

  def authorize_owner
    unless @avatar_owner_instance.can_edit?
      flash[:error] = "You can only change avatars of an item you have the permission to edit."
      redirect_to @avatar_owner_instance
    end
  end

  def avatar_params
    params.require(:avatar).permit(:image_file)
  end

  def find_avatars
    @avatars = @avatar_owner_instance.avatars
  end

  def find_avatar
    @avatar = @avatar_owner_instance.avatars.find(params[:id])
  end

  # this helper will store to session full form data of edited Person / Project / Institution
  # to allow users to go to "upload new avatar" screen without loosing any new data
  # that wasn't yet saved
  def store_unsaved_person_proj_inst_data_to_session
    data_hash = {}

    param = "#{@avatar_owner_instance.class.name.downcase}".to_sym

    return if params[param].nil?

    # all types will have main part of information in the generic form
    data_hash[param] = params[param]
    data_hash[param][:avatar_id] = nil if data_hash[param][:avatar_id].to_i == 0

    # collect any additional type-specific data from params
    case @avatar_for
    when "Person"
      data_hash[:description] = params[:description]
      data_hash[:tool] = params[:tool]
      data_hash[:expertise] = params[:expertise]

    when "Project"
      data_hash[:organism] = params[:organism]
      data_hash[:human_disease] = params[:human_disease]

    when "Institution"
      # no specific data to store for institutions so far

    end

    # store all collected data to session
    session["unsaved_#{@avatar_owner_instance.class.name}_#{@avatar_owner_instance.id}".to_sym] = data_hash
  end
end

