class AttachmentsController < ApplicationController

  def destroy
		@attachment = Attachment.find(params[:id])
    @attachment.destroy
		asset = @attachment.attachable
    asset.id_image = nil
    asset.save!
		@allowed = 5 - asset.attachments.count
	end

  def index
    @attachments = Attachment.all
  end

  def show
    @attachment = Attachment.find(params[:id])
  end
end
