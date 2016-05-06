class AvatarsController < ApplicationController

  skip_before_filter :project_membership_required

  before_filter :login_required, :except => [ :show ]
  before_filter :check_owner_specified
  before_filter :find_avatars, :only => [ :index ]
  before_filter :find_avatar_auth, :only => [ :show, :select, :edit, :update, :destroy ]
  
  cache_sweeper :avatars_sweeper,:only=>[:destroy,:select,:create]
  
  protect_from_forgery :except => [ :new ]

  include Seek::BreadCrumbs
  
  # GET /people/1/avatars/new
  # GET /people/new
  def new
    store_unsaved_person_proj_inst_data_to_session
    
    @avatar = Avatar.new
  end
  
  # POST /people/1/avatars
  # POST /people
  def create
    unless params[:avatar].blank? || params[:avatar][:image_file].blank?
      file_specified = true
      
      # the creation of the new Avatar instance needs to have only one parameter - therefore, the rest should be set separately
      @avatar = Avatar.new(params[:avatar])
      @avatar.owner_type = params[:owner_type]
      @avatar.owner_id = params[:owner_id]
      @avatar.original_filename = (params[:avatar][:image_file]).original_filename
    else
      file_specified = false
    end
    
    respond_to do |format|
      if file_specified && @avatar.save        
        
        # the last thing to check - if no avatar was selected for owner before (i.e. owner.avatar_id was NULL),
        # make the new avatar selected
        if @avatar.owner.avatar_id.nil?
          @avatar.owner.update_attribute(:avatar_id, @avatar.id)
        end
        
        flash[:notice] = 'Avatar was successfully uploaded.'
        
        # updated to take account of possibly various locations from where this method can be called,
        # so multiple redirect options are possible -> now return link is passed as a parameter
        format.html { redirect_to(params[:return_to] + "?use_unsaved_session_data=true") }
        
      else
        # "create" action was already called once; render it again
        @avatar = Avatar.new
        
        unless file_specified
          flash.now[:error] = "You haven't specified the filename. Please choose the image file to upload."
        else
          flash.now[:error] = "The image format is unreadable. Please try again or select a different image."
        end
        
        format.html { render :action => "new" }
      end
    end
  end
  
  # GET /users/1/avatars/1
  # GET /avatars/1 -> denied by before_filter
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
  # GET /avatars -> denied by before_filter
  def index
    respond_to do |format|
      format.html # index.rhtml
    end
  end
  
  
  # DELETE /users/1/avatars/1
  # DELETE /avatars/1 -> denied by before_filter
  def destroy
    owner = @avatar.owner
    
    @avatar.destroy
    
    respond_to do |format|
      format.html { redirect_to eval("#{owner.class.name.downcase}_avatars_url(#{owner.id})") }
    end
  end
  
  
  # GET /users/1/avatars/1/select
  # GET /avatars/1/select -> denied by before_filter
  def select
    if @avatar.select!
      ## IN CONTRAST TO myExperiment SysMO WILL NOT STORE PICTURE SELECTIONS (AT LEAST FOR NOW)
      # create and save picture selection record
      # PictureSelection.create(:user => current_user, :picture => @picture)
      ## END
      
      @avatar.save #forces a update callback, which invokes the sweeper
      if @avatar_owner_instance.is_a?(Project)
        if (Seek::Config.email_enabled && !@avatar_owner_instance.can_be_administered_by?(current_user))
          ProjectChangedEmailJob.new(@avatar_owner_instance).queue_job
        end
      end
      respond_to do |format|
        flash[:notice] = 'Profile avatar was successfully updated.'
        format.html { redirect_to eval("#{@avatar_owner_instance.class.name.downcase}_avatars_url(#{@avatar_owner_instance.id})") }
      end
    else
      respond_to do |format|
        flash[:error] = "Avatar was already selected."
        format.html { redirect_to url_for(@avatar_owner_instance) }
      end
    end
  end
  
  protected
  
  def determine_avatar_owner
    avatar_for = nil
    id = nil
    
    if params[:person_id]
      avatar_for = "Person"
      id = params[:person_id]
    elsif params[:project_id]
      avatar_for = "Project"
      id = params[:project_id]
    elsif params[:institution_id]
      avatar_for = "Institution"
      id = params[:institution_id]
    elsif params[:programme_id]
      avatar_for = "Programme"
      id = params[:programme_id]
    end
    
    return [avatar_for, id]
  end
  
  
  private
  
  def check_owner_specified
    @avatar_for, @avatar_for_id = determine_avatar_owner
    
    # check that nested route is used, not a direct link
    if (@avatar_for.nil? || @avatar_for_id.nil?)
      flash[:error] = "Avatars are only available for people, #{t('project').pluralize.downcase} and institutions."
      redirect_to(root_path)
      return false
    end
    
    begin
      # this will find person/project/institution which "owns" in the URL (if it is correct)
      @avatar_owner_instance = @avatar_for.constantize.find(@avatar_for_id)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Could not find the #{@avatar_for.downcase} for this avatar."
      redirect_to(root_path)
      return false
    end
  end
  
  
  def find_avatar_auth
    # can show avatars to anyone (given that avatar ID belongs to the avatar owner in the URL);
    # for all other actions some validation is required
    unless self.action_name.to_s == "show"
      if @avatar_for.downcase == "person"
        # for people, users can only edit/select/destroy own avatars - and "person" for current user should exist anyway;
        # (admins can access other people avatars too, provided that the person which is about to be changed is not admin themself)
        unless @avatar_for_id.to_i == current_person.id.to_i || @avatar_owner_instance.can_be_edited_by?(current_user)
          flash[:error] = "You can only view and manage your own avatars, but not ones of other users."
          redirect_to(person_path(current_person))
          return false
        end
      else
        # project / institution was found - now check if current user has permissions to edit/select/destroy avatars:
        # only selected members AND admins can do so
        unless @avatar_owner_instance.can_be_edited_by?(current_user)
          flash[:error] = "You can only view and, possibly, manage avatars of #{pluralize @avatar_for.downcase}, where you are a member of."
          redirect_to url_for(@avatar_owner_instance)
          return false
        end
      end
    end
    
    # current user is authorised to perform the desired action with avatars of the object in URL;
    # check if the avatar ID in the URL belongs to the specified object
    begin
      @avatar = Avatar.where(:owner_type => @avatar_for, :owner_id => @avatar_for_id).find( params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Avatar not found or belongs to a different #{@avatar_for.downcase}."
      redirect_to(root_path)
      return false
    end
    
  end
  
  
  def find_avatars
    # all avatars for current object are only shown to the owner of the object OR to any admin (if the object is not an admin themself);
    # also, show avatars to all members of a project/institution
    if (@avatar_owner_instance.respond_to?(:can_be_edited_by?) && @avatar_owner_instance.can_be_edited_by?(current_user))
      @avatars = Avatar.where(:owner_type => @avatar_for, :owner_id => @avatar_for_id)
    else
      flash[:error] = "You can only change avatars of an item you have the permission to edit."
      redirect_to(person_path(current_person))
      return false
    end
  end
  
  # this helper will store to session full form data of edited Person / Project / Institution
  # to allow users to go to "upload new avatar" screen without loosing any new data
  # that wasn't yet saved
  def store_unsaved_person_proj_inst_data_to_session
    data_hash = {}
    
    return if params["#{@avatar_for.downcase}".to_sym].nil?
    
    # all types will have main part of information in the generic form
    data_hash["#{@avatar_for.downcase}".to_sym] = params["#{@avatar_for.downcase}".to_sym]    
    data_hash["#{@avatar_for.downcase}".to_sym][:avatar_id] = nil if data_hash["#{@avatar_for.downcase}".to_sym][:avatar_id].to_i == 0
    
    # collect any additional type-specific data from params
    case @avatar_for
      when "Person"
      data_hash[:description] = params[:description]
      data_hash[:tool] = params[:tool]
      data_hash[:expertise] = params[:expertise]      
      
      when "Project"
      data_hash[:organism] = params[:organism]
      
      when "Institution"
      # no specific data to store for institutions so far
      
    end
    
    # store all collected data to session
    session["unsaved_#{@avatar_for}_#{@avatar_for_id}".to_sym] = data_hash
  end
  
end
