class HelpImagesController < ApplicationController
  include Seek::UploadHandling::DataUpload

  before_action :login_required
  before_action :is_user_admin_auth, :except => [:view]

  def view
    @help_image = HelpImage.find(params[:id])
    @content_blob = @help_image.content_blob
    image_size = params[:image_size]
    if image_size
      @content_blob.resize_image(image_size)
      filepath = @content_blob.full_cache_path(image_size)
      headers['Content-Length'] = File.size(filepath).to_s
    else
      filepath = @content_blob.filepath
      headers['Content-Length'] = @content_blob.file_size.to_s
    end

    send_file filepath, filename: @content_blob.original_filename, content_type: @content_blob.content_type, disposition: 'inline'
  end

  def create
    @help_document = HelpDocument.find_by_identifier(params[:help_document_id])
    @help_image = @help_document.images.build

    if handle_upload_data
      if @help_image.save
        @error_text = []
      else
        @error_text = @help_image.errors.full_messages
      end
    else
      @error_text = [flash[:error]]
    end

    @help_document.reload # Ensure unsaved (invalid) images are removed from the collection
    status = @error_text.empty? ? :ok : :bad_request
    respond_to do |format|
      format.html { render partial: 'help_documents/images', status: status }
    end
  end
  
  def destroy
    @help_image = HelpImage.find(params[:id])
    @help_document = @help_image.help_document
    @help_image.destroy

    respond_to do |format|
      format.html { render partial: 'help_documents/images' }
    end
  end
end
