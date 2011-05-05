class HelpAttachmentsController < ApplicationController
    
  before_filter :is_user_admin_auth, :except => [:download]
  
  def download
    @help_attachment = HelpAttachment.find(params[:id])
    send_data @help_attachment.db_file.data, :filename => @help_attachment.filename, :content_type => @help_attachment.content_type, :disposition => 'attachment'
  end

  def create
    @help_document = HelpDocument.find(params[:help_attachment][:help_document_id])
    @help_attachment = HelpAttachment.new(params[:help_attachment])
    if @help_attachment.save
      @error_text = []
    else
      @error_text = @help_attachment.errors.full_messages
    end
    responds_to_parent do
      render :update do |page|
        page.replace_html 'attachment_list', :partial => "help_documents/attachment_list", :locals => { :attachments => @help_document.attachments, :error_text => @error_text}
        page.replace_html 'attachments_count', @help_document.attachments.size.to_s
        page.visual_effect :highlight, 'attachment_list'
        page.hide 'attachment_spinner'
      end
    end    
  end
  
  def destroy
    @help_attachment = HelpAttachment.find(params[:id])
    @help_document = HelpDocument.find_by_identifier(params[:help_document_id])
    @help_attachment.destroy
    render :update do |page|
      page.replace_html 'attachment_list', :partial => "help_documents/attachment_list", :locals => { :attachments => @help_document.attachments, :error_text => @error_text}
      page.replace_html 'attachments_count', @help_document.attachments.size.to_s
      page.visual_effect :highlight, 'attachment_list'
    end
  end
  
end