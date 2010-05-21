class HelpImagesController < ApplicationController
  
  before_filter :login_required
  before_filter :is_user_admin_auth, :except => [:download]

  def create
    @help_document = HelpDocument.find(params[:help_image][:help_document_id])
    @help_image = HelpImage.new(params[:help_image])
    if @help_image.save
      @error_text = []
    else
      @error_text = @help_image.errors.full_messages
    end
    responds_to_parent do
      render :update do |page|
        page.replace_html 'image_list', :partial => "help_documents/image_list", :locals => { :images => @help_document.images, :error_text => @error_text}
        page.replace_html 'images_count', @help_document.images.size.to_s
        page.visual_effect :highlight, 'image_list'
        page.hide 'image_spinner'
      end
    end    
  end
  
  def destroy
    @help_image = HelpImage.find(params[:id])
    @help_document = HelpDocument.find_by_identifier(params[:help_document_id])
    @help_image.destroy
    render :update do |page|
      page.replace_html 'image_list', :partial => "help_documents/image_list", :locals => { :images => @help_document.images, :error_text => @error_text}
      page.replace_html 'images_count', @help_document.images.size.to_s
      page.visual_effect :highlight, 'image_list'
    end
  end
  
end