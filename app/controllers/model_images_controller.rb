class ModelImagesController < ApplicationController
  before_action :find_model_image_auth

  def show
    if params[:size]
      size = if params[:size] == 'large'
               ModelImage::LARGE_SIZE
             else
               params[:size]
             end
      @model_image.resize_image(size)
    end

    respond_to do |format|
      format.html do
        if size
          # Resized images are cached on local disk (per node) regardless of backend.
          path = @model_image.full_cache_path(size)
          send_file(path, type: 'image/png', disposition: 'inline')
          headers['Content-Length'] = File.size(path).to_s
        elsif @model_image.remote_storage?
          # The full-size master lives in object storage on S3 (no local file), so redirect to a
          # presigned URL and let the browser fetch it directly.
          redirect_to @model_image.storage_adapter.presigned_url(@model_image.storage_key,
                                                                 content_type: 'image/png',
                                                                 disposition: 'inline'),
                      allow_other_host: true
        else
          path = @model_image.file_path
          send_file(path, type: 'image/png', disposition: 'inline')
          headers['Content-Length'] = File.size(path).to_s
        end
      end
    end
  end

  private

  def find_model_image_auth
    @model = Model.find(params[:model_id])
    if is_auth?(@model, :view)
      @model_image = @model.model_images.where(id: params[:id]).first
      if @model_image.nil?
        flash[:error] = 'Image not found or belongs to a different model.'
        redirect_to root_path
      end
    else
      flash[:error] = "You can only view images for #{I18n.t('model').pluralize} you can access"
      redirect_to root_path
    end
  end
end
