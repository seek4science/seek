class HelpAttachmentsController < ApplicationController

  include Seek::UploadHandling::DataUpload

  before_action :documentation_enabled?
  before_action :is_user_admin_auth, :except => [:download]
  
  def download
    @help_attachment = HelpAttachment.find(params[:id])
    @content_blob = @help_attachment.content_blob
    send_file @content_blob.filepath, filename: @content_blob.original_filename, content_type: @content_blob.content_type, disposition: 'attachment'
  end

  def create
    @help_document = HelpDocument.find_by_identifier(params[:help_document_id])
    @help_attachment = @help_document.attachments.build(help_attachment_params)

    if handle_upload_data
      if @help_attachment.save
        @error_text = []
      else
        @error_text = @help_attachment.errors.full_messages
      end
    else
      @error_text = [flash[:error]]
    end

    @help_document.reload # Ensure unsaved (invalid) attachments are removed from the collection
    status = @error_text.empty? ? :ok : :bad_request
    respond_to do |format|
      format.html { render partial: 'help_documents/attachments', status: status }
    end
  end
  
  def destroy
    @help_attachment = HelpAttachment.find(params[:id])
    @help_document = @help_attachment.help_document
    @help_attachment.destroy

    respond_to do |format|
      format.html { render partial: 'help_documents/attachments' }
    end
  end

  private

  def help_attachment_params
    params.require(:help_attachment).permit(:title, :help_document_id)
  end

end