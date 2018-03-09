class ModelImagesController < ApplicationController
  before_filter :check_model_specified
  before_filter :find_model_images, only: [:index]
  before_filter :find_model_image_auth, only: %i[show select edit update destroy]

  def new
    @model_image = ModelImage.new
  end

  def create
    if params[:model_image].blank? || params[:model_image][:image_file].blank?
      file_specified = false
    else
      file_specified = true
      @model_image = ModelImage.new params[:model_image]
      @model_image.model_id = params[:model_id]
      @model_image.content_type = params[:model_image][:image_file].content_type
      @model_image.original_filename = params[:model_image][:image_file].original_filename
    end

    respond_to do |format|
      if file_specified && @model_image.save

        if @model_image.model.model_image_id.nil?
          @model_instance.update_attribute(:model_image_id, @model_image.id)
        end

        flash[:notice] = 'Image was successfully uploaded'
        format.html { redirect_to params[:return_to] }
      else
        @model_image = ModelImage.new
        if file_specified
          flash.now[:error] = 'The image format is unreadable. Please try again or select a different image.'
        else
          flash.now[:error] = "You haven't specified the filename. Please choose the image file to upload."
        end
        format.html { render action: 'new' }
      end
    end
  end

  def show
    params[:size] ||= ModelImage::DEFAULT_SIZE
    size = if params[:size] == 'large'
             ModelImage::LARGE_SIZE
           else
             params[:size]
           end

    @model_image.resize_image(size)

    respond_to do |format|
      format.html do
        path = @model_image.full_cache_path(size)
        send_file(path, type: 'image/jpeg', disposition: 'inline')
        headers['Content-Length'] = File.size(path).to_s
      end
      format.xml do
        @cache_file = @model_image.full_cache_path(size)
        @type = 'image/jpeg'
      end
    end
  end

  def filter_size(size)
    max_size = 1500
    matches = size.match(/([0-9]+)x([0-9]+).*/)
    if matches
      width = matches[1].to_i
      height = matches[2].to_i
      width = max_size if width > max_size
      height = max_size if height > max_size
      return "#{width}x#{height}"
    else
      matches = size.match(/([0-9]+)/)
      if matches
        width = matches[1].to_i
        width = max_size if width > max_size
        return width.to_s
      else
        return '900'
      end
    end
  end

  def index
    respond_to do |format|
      format.html
    end
  end

  def destroy
    model = @model_image.model
    @model_image.destroy
    respond_to do |format|
      format.html { redirect_to model_model_images_url model.id }
    end
  end

  def select
    if @model_image.select!

      @model_image.save
      respond_to do |format|
        flash[:notice] = "#{t('model')} image was successfully updated."
        format.html { redirect_to model_model_image_url @model_instance.id }
      end
    else
      respond_to do |format|
        flash[:error] = 'Image was already selected.'
        format.html { redirect_to url_for(@model_instance) }
      end
    end
  end

  private

  def check_model_specified
    @image_for = 'Model'
    @image_for_id = params[:model_id]

    begin
      @model_instance = Model.find(@image_for_id)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Could not find the #{@image_for.downcase} for this image."
      redirect_to(root_path)
      return false
    end
  end

  def find_model_images
    if @model_instance.can_view? current_user
      @model_images = ModelImage.where model_id: @image_for_id
    else
      flash[:error] = "You can only view images for #{t('model').pluralize} you can access"
      redirect_to root_path
    end
  end

  def find_model_image_auth
    action = Seek::Permissions::Translator.translate(action_name)
    unless is_auth?(@model_instance, action)
      flash[:error] = "You can only #{action} images for #{t('model').pluralize} you can access"
      redirect_to root_path
      return false
    end

    begin
      @model_image = ModelImage.where(model_id: @image_for_id).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = 'Image not found or belongs to a different model.'
      redirect_to root_path
      return false
    end
  end
end
