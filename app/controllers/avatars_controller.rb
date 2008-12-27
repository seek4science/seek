class AvatarsController < ApplicationController
  
  before_filter :login_required
  before_filter :check_owner_specified
  before_filter :find_avatars, :only => [ :index ]
  before_filter :find_avatar_auth, :only => [ :show, :select, :edit, :update, :destroy ]
  
  # GET /people/1/avatars/new
  # GET /people/new
  def new
    @avatar = Avatar.new
  end
  
  # POST /people/1/avatars
  # POST /people
  def create
    unless (params[:avatar][:image_file]).blank?
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
        
        #format.html { redirect_to pictures_url(@picture.user_id) }
        # updated to take account of possibly various locations from where this method can be called,
        # so multiple redirect options are possible -> now return link is passed as a parameter
        #format.html { redirect_to params[:redirect_to] }
        format.html { redirect_back_or_default(person_path(current_user.person)) }
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
    if params[:size] == "large"
      size = LARGE_SIZE
    else  
      size = params[:size] || "200x200"
    end
    size = size[0..-($1.length.to_i + 2)] if size =~ /[0-9]+x[0-9]+\.([a-z0-9]+)/ # trim file extension
    
    id = params[:id].to_i
    
    if cache_exists?(id, size) # look in file system cache before attempting db access
      send_file(full_cache_path(id, size), :type => 'image/jpeg', :disposition => 'inline')
    else
      # resize (keeping image side ratio), encode and cache the picture
      @avatar.operate do |image|
        image.resize size
        @image_binary = image.image.to_blob
      end
      
      # cache data
      cache_data!(@avatar, @image_binary, size)
      
      send_data(@image_binary, :type => 'image/jpeg', :disposition => 'inline')
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
      # IN CONTRAST TO myExperiment SysMO WILL NOT STORE PICTURE SELECTIONS (AT LEAST FOR NOW)
      # create and save picture selection record
      #PictureSelection.create(:user => current_user, :picture => @picture)
      # END
      
      respond_to do |format|
        flash[:notice] = 'Picture was successfully selected as profile picture.'
        format.html { redirect_back_or_default(person_path(current_user.person)) }
      end
    else
      flash[:error] = "Avatar was already selected"
      redirect_back_or_default(person_path(current_user.person))
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
      flash[:error] = "Please use nested routes. Avatars are only available for people, projects and institutions."
      redirect_back_or_default(person_path(current_user.person))
      return false
    end
    
    begin
      # this will find person/project/institution which "owns" in the URL (if it is correct)
      @avatar_owner_instance = eval("#{@avatar_for}.find(#{@avatar_for_id})")
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Could not find #{@avatar_for.downcase} specified in the URL."
      redirect_back_or_default(person_path(current_user.person))
      return false
    end
  end
  
  
  def find_avatar_auth
    unless @avatar_for.downcase == "person"
      # project / institution was found - now check if current user has permissions to view / edit avatars
      # TODO: security check to be implemented
    else
      # for people, users can only view own avatars - and "person" for current user should exist anyway
      unless current_user.person.id.to_i == @avatar_for_id.to_i
        flash[:error] = "You can only view and manage your own avatars."
        redirect_back_or_default(person_path(current_user.person))
        return false
      end
    end
    
    # current user is authorised to perform the desired action with avatars of the object in URL;
    # check if the avatar ID in the URL belongs to the specified object
    begin
      @avatar = Avatar.find( params[:id], :conditions => { :owner_type => @avatar_for, :owner_id => @avatar_for_id } )
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Avatar not found or belongs to a different #{@avatar_for.downcase}."
      redirect_back_or_default(person_path(current_user.person))
      return false
    end
    
  end
  
  
  def find_avatars
    @avatars = Avatar.find(:all, :conditions => { :owner_type => @avatar_owner_instance.class.name, :owner_id => @avatar_owner_instance.id })
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
  
end
