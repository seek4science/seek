class AvatarsController < ApplicationController

  skip_before_filter :project_membership_required

  before_filter :login_required, :except => [ :show ]
  before_filter :check_owner_specified
  before_filter :find_avatars, :only => [ :index ]
  before_filter :find_avatar_auth, :only => [ :show, :select, :edit, :update, :destroy ]
  
  cache_sweeper :avatars_sweeper,:only=>[:destroy,:select,:create]
  
  protect_from_forgery :except => [ :new ]
  
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
    size = size[0..-($1.length.to_i + 2)] if size =~ /[0-9]+x[0-9]+\.([a-z0-9]+)/ # trim file extension
    
    id = params[:id].to_i
    
    if !cache_exists?(id, size) # look in file system cache before attempting db access      
      # resize (keeping image side ratio), encode and cache the picture
      @avatar.operate do |image|
        image.resize size
        @image_binary = image.image.to_blob
      end      
      # cache data
      cache_data!(@avatar, @image_binary, size)            
    end
    
    respond_to do |format|
      format.html do
        send_file(full_cache_path(id, size), :type => 'image/jpeg', :disposition => 'inline')
      end
      format.xml do        
        @cache_file=full_cache_path(id, size)
        @type='image/jpeg'
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
    end
    
    return [avatar_for, id]
  end
  
  
  private
  
  def check_owner_specified
    @avatar_for, @avatar_for_id = determine_avatar_owner
    
    # check that nested route is used, not a direct link
    if (@avatar_for.nil? || @avatar_for_id.nil?)
      flash[:error] = "Avatars are only available for people, projects and institutions."
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
        unless @avatar_for_id.to_i == current_user.person.id.to_i || @avatar_owner_instance.can_be_edited_by?(current_user)
          flash[:error] = "You can only view and manage your own avatars, but not ones of other users."
          redirect_to(person_path(current_user.person))
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
      @avatar = Avatar.find( params[:id], :conditions => { :owner_type => @avatar_for, :owner_id => @avatar_for_id } )
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Avatar not found or belongs to a different #{@avatar_for.downcase}."
      redirect_to(root_path)
      return false
    end
    
  end
  
  
  def find_avatars
    # all avatars for current object are only shown to the owner of the object OR to any admin (if the object is not an admin themself);
    # also, show avatars to all members of a project/institution
    if User.admin_logged_in? || (@avatar_owner_instance.class.name == "Person" && @avatar_for_id.to_i == current_user.person.id.to_i) ||
     (["Project", "Institution"].include?(@avatar_for) && @avatar_owner_instance.people.include?(current_user))
      @avatars = Avatar.find(:all, :conditions => { :owner_type => @avatar_for, :owner_id => @avatar_for_id })
    else
      flash[:error] = "You can only view avatars that belong to you or any projects/institutions where you are a member of."
      redirect_to(person_path(current_user.person))
      return false
    end
  end
  
  
  # returns true if /avatars/show/:id?size=#{size}x#{size} is cached in file system
  def cache_exists?(avatar, size=nil)
    File.exists?(full_cache_path(avatar, size))
  end
  
  # caches data (where size = #{size}x#{size})
  def cache_data!(avatar, image_binary, size=nil)
    FileUtils.mkdir_p(cache_path(avatar, size))
    File.open(full_cache_path(avatar, size), "wb+") { |f| f.write(image_binary) }
  end
  
  def cache_path(avatar, size=nil, include_local_name=false)
    
    id = avatar.kind_of?(Integer) ? avatar : avatar.id
    rtn = "#{RAILS_ROOT}/tmp/avatars"
    rtn = "#{rtn}/#{size}" if size
    rtn = "#{rtn}/#{id}.#{Avatar.image_storage_format}" if include_local_name
    
    return rtn
  end
  
  def full_cache_path(avatar, size=nil) 
    cache_path(avatar, size, true) 
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
